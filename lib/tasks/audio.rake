namespace :audio do
  # app/ constants are not autoloadable at rake-file load time (lib/tasks
  # loads during boot), so all references live inside task bodies.

  desc "Render a listening sample across candidate voices to tmp/audio_validation/"
  task render_validation: :environment do
    require "fileutils"

    voice_candidates = Audio::SsmlBuilder::VOICE_CANDIDATES

    # Deliberate sample: sandhi words, polyphones, plain words — the exact
    # cases where TTS voices differ. Forced readings are in the app's own
    # diacritic notation, so they exercise PinyinNormalizer end to end.
    # Sandhi words must exist as real cards (一个 does not) — sandhi is
    # the signal most likely to differ between voices, and real cards
    # also test the actual pinyin storage.
    SAMPLE = {
      sandhi: %w[一样 不过 不好意思 一般 一会儿 不错 不客气],
      polyphones: {
        "行" => "xíng", "得" => "dé", "了" => "le", "长" => "cháng",
        "都" => "dōu", "还" => "hái", "觉" => "jué", "乐" => "lè",
        "地" => "dì"
      },
      plain: %w[安静 安排 报纸 比较 表演 冰箱 菜单 参加 操作
                试 是 四 十 没事儿 哪儿 女儿 银行]
    }.freeze

    out = Rails.root.join("tmp/audio_validation")
    FileUtils.rm_rf(out)
    FileUtils.mkdir_p(out)

    voice_candidates.each do |slug, voice_name|
      dir = out.join(slug)
      FileUtils.mkdir_p(dir)

      # Both hint modes for every word: the A/B that decides polyphone
      # strategy is hinted-vs-lexicon, not just voice-vs-voice.
      { hinted: Audio::SsmlBuilder::HINT_ALL, lexicon: Audio::SsmlBuilder::HINT_NONE }.each do |mode, hint|
        mode_dir = dir.join(mode.to_s)
        FileUtils.mkdir_p(mode_dir)
        builder = Audio::SsmlBuilder.new(voice: voice_name, hint: hint)

        (SAMPLE[:sandhi] + SAMPLE[:polyphones].keys + SAMPLE[:plain]).uniq.each do |word|
          card = Flashcard.find_by(character: word)
          reading = SAMPLE[:polyphones][word]

          source = if reading
                     OpenStruct.new(character: word, pinyin: reading)
                   elsif card
                     card
                   else
                     puts "  ! no card for #{word}, skipping"
                     next
                   end
          begin
              # Build once: the SSML is both the request body and the
              # diagnostic artifact if it's rejected (mismatch or Azure).
              ssml = builder.call(source)
              bytes = Audio::AzureTts.synthesize(ssml: ssml)
              unless Audio::SilenceGuard.valid?(bytes)
                puts "  ! silence guard rejected #{word} (#{mode})"
                next
              end
              File.binwrite(mode_dir.join("#{word}.mp3"), bytes)
            rescue StandardError => e
              # One bad word must not kill a ~150-word listening pass:
              # report and keep going. The rejected SSML is saved next to
              # the sample so the failure can be replayed/inspected
              # without guessing what was sent.
              puts "  ! #{word} (#{mode}): #{e.class}: #{e.message.to_s.slice(0, 400)}"
              File.binwrite(mode_dir.join("#{word}.rejected-ssml"), ssml.to_s) if ssml
            end
        end
      end
      puts "Wrote #{slug} samples to #{dir}"
    end

    puts "\nNEXT: listen for (1) 不/一 sandhi, (2) tone clarity on 试/是/四,"
    puts "(3) polyphone readings 行/得/了/长/都/还. Then set"
    puts "HANZITRAIL_AUDIO_VOICE=<slug> and run rails \"audio:render[hsk3]\"."
  end

  desc "Render missing audio: rails \"audio:render[hsk3]\" or \"audio:render[all]\""
  task :render, [:scope] => :environment do |_, args|
    scope = args[:scope] || "hsk3"

    cards = Flashcard.where(audio_key: nil)
    cards = cards.where(hsk_level: "new-3") if scope == "hsk3"

    voice_candidates = Audio::SsmlBuilder::VOICE_CANDIDATES
    voice_slug = ENV.fetch("HANZITRAIL_AUDIO_VOICE", "xiaoxiao")
    builder = Audio::SsmlBuilder.new(voice: voice_candidates.fetch(voice_slug))

    puts "Rendering #{cards.count} cards (#{scope}, voice #{voice_slug})…"

    # Per-card commit: a killed ssh session or Fly scale-down loses at most
    # the in-flight card (the HSK-import lesson), and the NULL-scope makes
    # re-runs resume where they stopped.
    failed = 0
    cards.find_each do |card|
      begin
        bytes = Audio::AzureTts.synthesize(ssml: builder.call(card))
        raise "silence guard rejected render" unless Audio::SilenceGuard.valid?(bytes)

        # Key encodes card + voice: objects are immutable, and a future
        # voice change gets a new key instead of overwriting history.
        key = "words/#{card.id}-#{voice_slug}.mp3"
        AudioStorage.upload!(key, bytes)
        card.update_columns(audio_key: key)
        print "."
      rescue StandardError => e
        failed += 1
        puts "\nFAIL #{card.id} #{card.character}: #{e.class}: #{e.message}"
      end
    end

    remaining = Flashcard.where(audio_key: nil).count
    puts "\nDone. Failed: #{failed}. Remaining without audio: #{remaining}"
  end
end
