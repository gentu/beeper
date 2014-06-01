#!/usr/bin/ruby
class Melody
  def run arg
    i = 0
    p = Proc.new do
      loop do
        if i == 0
          i = 1
        else
          puts "This melody has been played #{i} times"
          i += 1
        end
        send arg
      end
    end
    puts "Start \"#{arg}\" melody"
    begin
      p.call
    rescue NoMethodError
      puts "ERROR: Melody \"#{arg}\" is not found"
      arg = 'classic'
      i -= 1
      p.call
    end
  end
  def classic
    freq = 0
    while freq < 4500 do
        freq += 300
        unless system "beep -f #{freq} -l 100 >/dev/null"
          puts "bug freq #{freq}"
        end
    end
    while freq > 100 do
        freq -= 100
        unless system "beep -f #{freq} -l 100 >/dev/null"
          puts "bug freq #{freq}"
        end
    end
    60.times do
      system "beep -f #{Random.rand(4500) + 1} \
        -l #{Random.rand(500) + 100} >/dev/null"
    end
  end
end

melody = Melody.new

if ARGV[0].nil?
  system 'beep -f 5000 -n -f 8000'
  exit
end

melody.run ARGV[0]
