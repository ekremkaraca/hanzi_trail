namespace :audio do
  # app/ constants are not autoloadable at rake tasks-load time (lib/tasks
  # loads during boot), so all references live inside task bodies.
  #
  # This task is designed to run LOCALLY, not on the prod machine: it
  # writes nothing to the database (cards are read only for their real
  # pinyin — a seeded local DB has the full HSK deck) and exists so a
  # human can listen to candidate voices. A full Rails boot co-running
  # with the web app OOM-killed the 512MB prod machine and 503'd the
  # site; locally it is just API calls and MP3 files.

  desc "Render a listening sample across candidate voices to tmp/audio_validation/"
  task render_validation: :environment do
    require "fileutils"

    voice_candidates = Audio::SsmlBuilder::VOICE_CANDIDATES

    # Deliberate sample: sandhi words, polyphones, and plain words —
    # the cases where voices differ most. All real cards; readings are
    # whatever each voice's lexicon chooses, which is exactly what the
    # ear must judge since <phoneme> hinting is unavailable (rejected
    # with 400 by the endpoint).
    SAMPLE = {
      sandhi: %w[一样 不过 不好意思 一般 一会儿 不错 不客气],
      polyphones: %w[行 得了 长大 都是 还有 觉得 音乐 地铁 银行],
      plain: %w[安静 安排 报纸 比较 表演 冰箱 菜单 参加 操作
                试 是 四 十 没事儿 哪儿 女儿]
    }.freeze

    out = Rails.root.join("tmp/audio_validation")
    FileUtils.rm_rf(out)
    FileUtils.mkdir_p(out)

    voice_candidates.each_value do |voice_name|
      slug = voice_name.sub("zh-CN-", "").sub("Neural", "").downcase
      dir = out.join(slug)
      FileUtils.mkdir_p(dir)
      builder = Audio::SsmlBuilder.new(voice: voice_name)

      sample_words = SAMPLE.values.flatten.uniq
      puts "Rendering #{sample_words.size} words with #{voice_name}…"

      sample_words.each do |word|
        card = Flashcard.find_by(character: word)
        unless card
          puts "  ! no card for #{word}, skipping"
          next
        end

        begin
          ssml = builder.call(card)
          bytes = Audio::AzureTts.synthesize(ssml: ssml)
          unless Audio::SilenceGuard.valid?(bytes)
            puts "  ! silence guard rejected #{word}"
            next
          end
          File.binwrite(dir.join("#{word}.mp3"), bytes)
        rescue StandardError => e
          # One bad word must not kill the pass: report, keep going, and
          # save the rejected SSML so the failure can be replayed.
          puts "  ! #{word}: #{e.class}: #{e.message.to_s.slice(0, 400)}"
          File.binwrite(dir.join("#{word}.rejected-ssml"), ssml.to_s) if defined?(ssml) && ssml
        end
      end

      puts "Wrote samples to #{dir}"
    end

    puts "\nNEXT: listen for (1) 不/一 tone sandhi (一样, 不过, 不好意思),"
    puts "(2) tone clarity on 试/是/四/十, (3) polyphone readings in words"
    puts "(长大, 都是, 还有, 觉得, 音乐, 地铁, 银行)."
    puts "Then set HANZITRAIL_AUDIO_VOICE=<slug> and run audio:render[hsk3]."
  end

  desc "Render missing audio: rails \"audio:render[hsk3]\" or \"audio:render[all]\""
  task :render, [:scope] => :environment do |_, args|
    scope = args[:scope] || "hsk3"

    cards = Flashcard.where(audio_key: nil)
    cards = cards.where(hsk_level: "new-3") if scope == "hsk3"

    voice_slug = ENV.fetch("HANZITRAIL_AUDIO_VOICE", "xiaoxiao")
    voice_name = Audio::SsmlBuilder::VOICE_CANDIDATES.fetch(voice_slug)
    builder = Audio::SsmlBuilder.new(voice: voice_name)

    puts "Rendering #{cards.count} cards with #{voice_name} (scope: #{scope})"

    # Per-card commit: a killed or OOM'd run loses at most the in-flight
    # card, and re-runs resume from the NULL-scope.
    failed = 0
    cards.find_each do |card|
      begin
        ssml = builder.call(card)
        bytes = Audio::AzureTts.synthesize(ssml: ssml)
        unless Audio::SilenceGuard.valid?(bytes)
          puts "\n! silence guard rejected #{card.character}"
          failed += 1
          next
        end

        # Key encodes card + voice: objects are immutable per key, and a
        # future voice switch gets fresh keys instead of overwriting.
        key = "words/#{card.id}-#{voice_slug}.mp3"
        AudioStorage.upload!(card, key, bytes)
        card.update_columns(audio_key: key)
        print "."
      rescue StandardError => e
        failed += 1
        puts "\n! FAIL #{card.character}: #{e.class}: #{e.message.to_s.slice(0, 300)}"
      end
    end

    puts "\nDone. Failed: #{failed}. Remaining without audio: #{Flashcard.where(audio_key: nil).count}"
  end
end
