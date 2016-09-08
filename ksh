#!/usr/bin/env ruby
require 'optparse'
require 'pp'

def usage
    "Usage: ksh <pod> [-c container] [--context CONTEXT] [--namespace NAMESPACE] [-- COMMAND]"
end

command = "bash"
if ARGV.index("--")
    command = ARGV[ARGV.index("--") + 1..-1].join(" ")
end

$container = nil
$global_opts = {}
OptionParser.new do |o|
  o.banner = usage
  o.on('-c', '--container CONTAINER', "container") {|c| $container = c }
  o.on('--context MANDATORY', "context") {|c| $global_opts[:context] = "--context=#{c}" }
  o.on('-nNAMESPACE', '--namespace NAMESPACE', "namespace") {|n| $global_opts[:namespace] = "--namespace=#{n}" }
end.parse!
$global_opts = $global_opts.values.join(' ')

def match_pod(pattern)
    pods = `kubectl #{$global_opts} get pods | egrep "#{pattern}" | grep -v Terminating | awk '{ print $1 }'`.split("\n")
    if pods.length == 1
        return pods[0]
    end

    puts "pods found:"
    pods.each_index do |i|
        puts "  #{i}:\t#{pods[i]}"
    end

    while true
        print "select a pod by its index above [#{pods[0]}]: "
        index = STDIN.gets.chomp.to_i
        if !pods[index].nil?
            return pods[index]
        end
        puts "pods[#{index}] does not exist"
    end
end

def match_container(pod, pattern)

    containers = `kubectl #{$global_opts} get -o jsonpath='{ .spec.containers[*].name }' pods/#{pod}`.split(" ")

    if pattern
        matched_containers = containers.select {|c| c[pattern] }
        if matched_containers.length == 0
            abort("no container matching #{pattern} in pod=#{pod} ... containers: #{containers}")
        end
        containers = matched_containers
    end

    if containers.length == 1
        return containers.first
    else # multiple containers, user needs to choose
        puts "containers:"
        containers.each_index do |i|
            puts "  #{i}:\t#{containers[i]}"
        end
        while true
            print "select a container by its index above [#{containers[0]}]: "
            index = STDIN.gets.chomp.to_i
            if containers[index].nil?
                puts "containers[#{index}] does not exist"
            else
                return containers[index]
            end
        end

    end
end

abort(usage) if ARGV.length == 0

pod = match_pod(ARGV.shift)
if !pod.nil?

    $container = match_container(pod, $container)
    if !$container.nil?
        $container = "-c #{$container}"
    end

    COLUMNS, LINES =`tput cols`.chomp, `tput lines`.chomp
    exec( "set -x; kubectl #{$global_opts} exec -it #{pod} #{$container} env COLUMNS=#{COLUMNS} LINES=#{LINES} TERM=xterm #{command}; set +x" )

end
