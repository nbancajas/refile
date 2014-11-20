RSpec.describe Defile::Backend::FileSystem do
  let(:backend) { Defile::Backend::FileSystem.new(File.expand_path("tmp/store1", Dir.pwd)) }

  it_behaves_like :backend

  describe "#upload" do
    it "efficiently copies a file if it has a path" do
      path = File.expand_path("tmp/test.txt", Dir.pwd)
      File.write(path, "hello")

      uploadable = Defile::FileDouble.new("wrong")
      allow(uploadable).to receive(:path).and_return(path)

      file = backend.upload(uploadable)

      expect(backend.get(file.id).read).to eq("hello")
    end

    it "ignores path if it doesn't exist" do
      path = File.expand_path("tmp/doesnotexist.txt", Dir.pwd)

      uploadable = Defile::FileDouble.new("yes")
      allow(uploadable).to receive(:path).and_return(path)

      file = backend.upload(uploadable)

      expect(backend.get(file.id).read).to eq("yes")
    end
  end

  describe "#stream" do
    if defined?(ObjectSpace) # usually doesn't exist on JRuby
      it "doesn't leak file descriptors" do
        file = backend.upload(Defile::FileDouble.new("hello"))

        before = ObjectSpace.each_object(File).reject { |f| f.closed? }

        expect(backend.stream(file.id).to_a.join).to eq("hello")

        after = ObjectSpace.each_object(File).reject { |f| f.closed? }

        expect(after).to eq(before)
      end
    end
  end
end