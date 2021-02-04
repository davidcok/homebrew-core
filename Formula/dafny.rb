class Dafny < Formula
  desc "Verification-aware programming language"
  homepage "https://github.com/dafny-lang/dafny/blob/master/README.md"
  url "https://github.com/dafny-lang/dafny/archive/v3.0.0.tar.gz"
  sha256 "5e9af6ca59c3329cd93d792bf9890c55c68c4f656afb19c85d1c44b0c7989fc2"
  license "MIT"
  revision 4

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    cellar :any_skip_relocation
    sha256 "67bef401bfee4518789c1a12e72beeaeb7359d8c4d388dc89ab7427b4136e9ef" => :big_sur
    sha256 "3c73b8c0c0f1b204f1118ef40c857418e112f6c5aac3c299d1be3abefce1704f" => :catalina
    sha256 "3a21de05e53a0276a2aaaf3e82f2f8062b02ae9e31ba2a7bd0b2631691d10eca" => :mojave
  end

  depends_on "nuget" => :build
  depends_on "dotnet"

  # Use the following along with the z3 build below, as long as dafny
  # cannot build with latest z3 (https://github.com/dafny-lang/dafny/issues/810)
  resource "z3" do
    url "https://github.com/Z3Prover/z3/archive/Z3-4.8.5.tar.gz"
    sha256 "4e8e232887ddfa643adb6a30dcd3743cb2fa6591735fbd302b49f7028cdc0363"
  end

  def install
    system "make", "exe", "runtime"

    libexec.install Dir["Binaries/*", "Scripts/quicktest.sh"]
    (libexec/"dafny").write <<~EOS
      #! /bin/bash
      dotnet /usr/local/Cellar/dafny/3.0.0_4/libexec/Dafny.dll "$@"
    EOS
    bin.install libexec/"dafny"

    dst_z3_bin = libexec/"z3/bin"
    dst_z3_bin.mkpath

    resource("z3").stage do
      system "./configure"
      system "make", "-C", "build"
      mv("build/z3", dst_z3_bin/"z3")
    end
  end

  test do
    (testpath/"test.dfy").write <<~EOS
      method Main() {
        var i: nat;
        assert i as int >= -1;
        print "hello, Dafny\\n";
      }
    EOS
    assert_equal "\nDafny program verifier finished with 1 verified, 0 errors\n",
                  shell_output("dotnet #{libexec}/Dafny.dll /compile:0 #{testpath}/test.dfy")
    assert_equal "\nDafny program verifier finished with 1 verified, 0 errors\nRunning...\n\nhello, Dafny\n",
                  shell_output("dotnet #{libexec}/Dafny.dll /compile:3 #{testpath}/test.dfy")
    assert_equal "Z3 version 4.8.5 - 64 bit\n",
                 shell_output("#{libexec}/z3/bin/z3 -version")
  end
end
