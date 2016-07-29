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

opts = { container: "", context: "", namespace: "" }
OptionParser.new do |o|
  o.banner = usage
  o.on('-c', '--container [CONTAINER]', "container") {|c| opts[:container] = c }
  o.on('--context [MANDATORY]', "context") {|c| opts[:context] = "--context=#{c}" }
  o.on('--namespace [NAMESPACE]', "namespace") {|n| opts[:namespace] = "--namespace=#{n}" }
end.parse!

def match_pod(pattern)
    pods = `kubectl get pods | egrep "#{pattern}" | grep -v Terminating | awk '{ print $1 }'`.split("\n")
    if pods.length == 1
        return pods[0]
    else

        puts "pods found:"
        pods.each_index do |i|
            puts "  #{i}:\t#{pods[i]}"
        end

        while true
            print "select a pod by its index above [#{pods[0]}]: "
            index = STDIN.gets.chomp.to_i
            if pods[index].nil?
                puts "pods[#{index}] does not exist"
            else
                return pods[index]
            end
        end
    end
end

def match_container(pod, pattern)

    containers = `kubectl get -o jsonpath='{ .spec.containers[*].name }' pods/#{pod}`.split(" ")

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
    container = match_container(pod, opts[:container])
    opts[:container] = "-c #{container}"
end

COLUMNS=`tput cols`.chomp
LINES=`tput lines`.chomp
TERM="xterm"

options = opts.each_value.map {|v| v }.join(" ")
exec( "kubectl exec -it #{pod} #{options} env COLUMNS=#{COLUMNS} LINES=#{LINES} TERM=#{TERM} #{command}" )
