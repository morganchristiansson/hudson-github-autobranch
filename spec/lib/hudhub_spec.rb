require 'spec_helper'

describe Hudhub do
  let(:github_payload) do
    <<-EOS
{
"before": "5aef35982fb2d34e9d9d4502f6ede1072793222d",
"repository": {
"url": "http://github.com/defunkt/github",
"name": "github",
"description": "You're lookin' at it.",
"watchers": 5,
"forks": 2,
"private": 1,
"owner": {
  "email": "chris@ozmm.org",
  "name": "defunkt"
}
},
"commits": [
{
  "id": "41a212ee83ca127e3c8cf465891ab7216a705f59",
  "url": "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
  "author": {
    "email": "chris@ozmm.org",
    "name": "Chris Wanstrath"
  },
  "message": "okay i give in",
  "timestamp": "2008-02-15T14:57:17-08:00",
  "added": ["filepath.rb"]
},
{
  "id": "de8251ff97ee194a289832576287d6f8ad74e3d0",
  "url": "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
  "author": {
    "email": "chris@ozmm.org",
    "name": "Chris Wanstrath"
  },
  "message": "update pricing a tad",
  "timestamp": "2008-02-15T14:36:34-08:00"
}
],
"after": "de8251ff97ee194a289832576287d6f8ad74e3d0",
"ref": "refs/heads/da-branch"
}
    EOS
  end

  let(:github_payload_branch_deleted) do
    JSON.parse(github_payload).merge("deleted" => true).to_json
  end

  before do
    allow(Hudhub::Job::Http).to receive(:get)
    allow(Hudhub::Job::Http).to receive(:post)
  end

  describe "##process_github_hook" do
    context "when github_token doesn't match the one stored in config" do
      it "should raise InvalidGithubToken error" do
        expect { Hudhub.process_github_hook('INVALID_TOKEN', github_payload) }.to raise_error
      end
    end

    context "when github_token matches the one stored in config" do
      xit "should not raise InvalidGithubToken error" do
        expect { Hudhub.process_github_hook('1234ABCD', github_payload) }.not_to raise_error
      end

      let(:the_job) { Hudhub::Job.new('my_project', 'some xml')}

      context "when the payload object does not contain the key 'deleted'" do
        it "should call Job.find_or_create_copy.run!" do
          expect(Hudhub::Job).to receive(:find_or_create_copy).with('my_project', 'da-branch') { the_job }
          expect(the_job).to receive(:run!)
          Hudhub.process_github_hook('1234ABCD', github_payload)
        end
      end

      context "when the payload object contains the key 'deleted'" do
        it "should call Job.delete!" do
          expect(Hudhub::Job).to receive(:delete!).with('my_project', 'da-branch')
          Hudhub.process_github_hook('1234ABCD', github_payload_branch_deleted)
        end
      end

    end
  end

  describe "#branch" do
    it "should extract branch from github_payload" do
      expect(Hudhub.new('1234ABCD', github_payload).branch).to eq 'da-branch'
    end
  end

  describe "#branch_deleted?" do
    context "when github_payload does not contain the key 'deleted'" do
      it "should be false" do
        expect(Hudhub.new('1234ABCD', github_payload).branch_deleted?).to eq false
      end
    end

    context "when github_payload contains the key 'deleted'" do
      it "should be true" do
        expect(Hudhub.new('1234ABCD', github_payload_branch_deleted).branch_deleted?).to eq true
      end
    end
  end

  describe "##config" do
    subject { Hudhub.config }
    its(:github_token) { should == '1234ABCD' }
    its(:hudson_url)   { should == 'http://hudson.your-organization.com' }
    its(:base_jobs)    { should == ['my_project'] }
  end
end
