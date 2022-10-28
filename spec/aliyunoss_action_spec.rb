describe Fastlane::Actions::AliyunossAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The aliyunoss plugin is working!")

      Fastlane::Actions::AliyunossAction.run(nil)
    end
  end
end
