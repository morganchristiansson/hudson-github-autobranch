#!/usr/bin/env ruby
require './hudhub'

# ARGS: <oldrev> <newrev> <refname>
oldrev, newrev, refname = ARGV
branch = refname.split("refs/heads/").last

Hudhub.config.base_jobs.each do |base_job_name|
  #if branch_deleted?
  #  Job.delete!(base_job_name, branch)
  #else
    Hudhub::Job.find_or_create_copy(base_job_name, branch).run!
  #end
end

