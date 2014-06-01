#!/usr/bin/ruby
require "optparse"
require 'optparse/time'
require 'ostruct'
require 'time'

class Application
  def initialize
    params = parse_options
    unless system 'beeper_melody.rb'
      puts 'Melody test failed'
      exit
    end
    input = Thread.new { loop do get_input end }
    timer = set_timer(params)
    cur_time = Time.now
    puts "Current time is #{cur_time}"
    puts "Alarm setted to #{cur_time + timer}"
    waiting timer
    run
    input.join
  end

  def get_input
    grade = gets.chomp
    case grade
      when 'stop'
        Process.kill "TERM", @run_pid rescue Errno::ESRCH
        exit
      when 'pause'
        Thread.new {
          Process.kill "TERM", @run_pid
          pause_time = 900 #15 minutes
          puts "Alarm has been paused. Next alarm at #{(Time.now + pause_time).strftime('%H:%M:%S')}"
          waiting pause_time #15 minutes
          run
        }
      else
        puts "Wrong command!"
    end
  end

  def run
    @run_pid = fork do
      exec 'beeper_melody.rb classic cycle'
    end
    begin
      Process.wait
    rescue Interrupt
      Process.kill "TERM", @run_pid
    end
  end

  def set_timer params
    date = params.timeset
    hours = params.hours || 0
    minutes = params.minutes || 0
    seconds = params.seconds || 0
    unless date.nil?
      Time.now.sec - date.sec
    else
      (hours * 60 * 60) + (minutes * 60) + seconds
    end
  end

  def waiting seconds
    begin
      sleep seconds
    rescue Interrupt
      puts 'Alarm has been canceled'
      exit
    end
  end

  def parse_options
    options = OpenStruct.new
    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: beeper [options]"
      opts.separator ""
      opts.separator "Specific options:"

      opts.on( '-d', '--date [DATE]', Time, 'Set alarm time' ) do |date|
        options.timeset = date
      end
      opts.on( '-h', '--hours [DECIMAL]', OptionParser::DecimalInteger, 'Set hour for timer' ) do |hours|
        options.hours = hours
      end
      opts.on( '-m', '--minutes [DECIMAL]', OptionParser::DecimalInteger, 'Set minute for timer' ) do |minutes|
        options.minutes = minutes
      end
      opts.on( '-s', '--seconds [DECIMAL]', OptionParser::DecimalInteger, 'Set second for timer' ) do |seconds|
        options.seconds = seconds
      end
      opts.on( '-t', '--time XX[:XX][:XX]', 'Set time for timer' ) do |t|
        time = t.split(/:/).map(&:to_i)
        options.hours = time[0] || 0
        options.minutes = time[1] || 0
        options.seconds = time[2] || 0
      end
    end

    begin
      optparse.parse!
      if options.hours.nil? && options.minutes.nil? && options.seconds.nil? && options.timeset.nil?
        puts optparse
        exit
      end
    rescue OptionParser::InvalidArgument, OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!.to_s
      puts optparse
      exit
    end
    options
  end
end

Application.new
