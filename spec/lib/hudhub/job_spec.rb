require 'spec_helper'

describe Hudhub::Job do

  let(:response_200) do
    double('response', code: 200)
  end

  before do
    allow(Hudhub::Job::Http).to receive(:get) { response_200 }
    allow(Hudhub::Job::Http).to receive(:post) { response_200 }
  end

  let(:base_job) do
    Hudhub::Job.new('my_project_master_rspec', <<-XML)
<?xml version='1.0' encoding='UTF-8'?>
<project>
  <actions/>
  <description></description>
  <logRotator>
    <daysToKeep>-1</daysToKeep>
    <numToKeep>50</numToKeep>
    <artifactDaysToKeep>-1</artifactDaysToKeep>
    <artifactNumToKeep>-1</artifactNumToKeep>
  </logRotator>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty>
      <projectUrl>https://github.com/versapay/hudson-github-autobranch/</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <hudson.queueSorter.PrioritySorterJobProperty>
      <priority>100</priority>
    </hudson.queueSorter.PrioritySorterJobProperty>
  </properties>
  <scm class="hudson.plugins.git.GitSCM">
    <configVersion>2</configVersion>
    <userRemoteConfigs>
      <hudson.plugins.git.UserRemoteConfig>
        <name>origin</name>
        <refspec>+refs/heads/*:refs/remotes/origin/*</refspec>
        <url>git://github.com/versapay/hudson-github-autobranch.git</url>
      </hudson.plugins.git.UserRemoteConfig>
    </userRemoteConfigs>
    <branches>
      <hudson.plugins.git.BranchSpec>
        <name>origin/template</name>
      </hudson.plugins.git.BranchSpec>
    </branches>
    <recursiveSubmodules>false</recursiveSubmodules>
    <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
    <authorOrCommitter>false</authorOrCommitter>
    <clean>false</clean>
    <wipeOutWorkspace>false</wipeOutWorkspace>
    <pruneBranches>false</pruneBranches>
    <remotePoll>false</remotePoll>
    <buildChooser class="hudson.plugins.git.util.DefaultBuildChooser"/>
    <gitTool>Default</gitTool>
    <submoduleCfg class="list"/>
    <relativeTargetDir></relativeTargetDir>
    <excludedRegions></excludedRegions>
    <excludedUsers></excludedUsers>
    <gitConfigName></gitConfigName>
    <gitConfigEmail></gitConfigEmail>
    <skipTag>false</skipTag>
    <scmName></scmName>
  </scm>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers class="vector"/>
  <concurrentBuild>false</concurrentBuild>
  <builders/>
  <publishers/>
  <buildWrappers/>
</project>
    XML
  end
  let(:job) { Hudhub::Job.copy!(base_job, 'new-branch') }

  describe "#name_for_branch" do
    context "when my-project-master-rspec" do
      subject { Hudhub::Job.name_for_branch("my-project-master-rspec", "new-branch") }
      it { should == "my-project-new-branch-rspec" }
    end
    context "when my-project-rspec" do
      subject { Hudhub::Job.name_for_branch("my-project-rspec", "new-branch") }
      it { should == "my-project-rspec-new-branch" }
    end
  end

  describe "#update_branch!" do
    context "when branch is 'new-branch'" do
      subject { base_job.update_branch!('new-branch')}

      its(:name) { should == 'my_project_new-branch_rspec'}
      it "has the correct name" do
        xml = REXML::Document.new(subject.data)
        expect(REXML::XPath.first(xml, '/project/scm/branches/hudson.plugins.git.BranchSpec/name').text).to eq 'origin/new-branch'
      end
    end
  end

  describe "##find_or_create_copy" do
    context "when job exists" do
      it "should return the job" do
        expect(Hudhub::Job).to receive(:find).with('my_project_new-branch_spec') { job }
        expect(Hudhub::Job.find_or_create_copy('my_project_master_spec', 'new-branch')).to eq job
      end
    end
    context "when job does not exists" do
      it "should create a copy" do
        job #evaluate let block before stubs
        expect(Hudhub::Job).to receive(:find).with('my_project_new-branch_spec') { nil }
        expect(Hudhub::Job).to receive(:find).with('my_project_master_spec') { base_job }
        expect(Hudhub::Job).to receive(:copy!).with(base_job, 'new-branch') { job }

        expect(Hudhub::Job.find_or_create_copy('my_project_master_spec', 'new-branch')).to eq job
      end
    end
  end

  describe "##copy!" do
    it "should create a job based on the base one" do
      expect(Hudhub::Job::Http).to receive(:post).
        with("/createItem?name=my_project_new-branch_rspec",
             {:body=>job.data}) { response_200 }
      Hudhub::Job.copy!(base_job, 'new-branch')
    end
    describe "the job returned" do
      subject { Hudhub::Job.copy!(base_job, 'new-branch')}

      its(:name) { should == 'my_project_new-branch_rspec' }
      it "has the correct name" do
        xml = REXML::Document.new(subject.data)
        expect(REXML::XPath.first(xml, '/project/scm/branches/hudson.plugins.git.BranchSpec/name').text).to eq 'origin/new-branch'
      end
    end
  end

  describe "##delete!" do
    it "should delete the job" do
      expect(Hudhub::Job::Http).to receive(:post).
        with("/job/my_project_old-branch_rspec/doDelete")
      Hudhub::Job.delete!(base_job.name, 'old-branch')
    end
  end
end

