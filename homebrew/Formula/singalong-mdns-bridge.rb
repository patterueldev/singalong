class SinglealongMdnsBridge < Formula
  desc "mDNS bridge for Singalong Node service discovery on LAN"
  homepage "https://github.com/patterueldev/singalong"
  url "https://github.com/patterueldev/singalong/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "TODO_UPDATE_WITH_ACTUAL_SHA256"
  license "MIT"
  
  depends_on "python@3.11"
  depends_on "poetry"
  
  def install
    # Install the mdns-bridge application into cellar
    cd "apps/singalong-mdns-bridge"
    
    # Create virtualenv and install dependencies
    system "poetry", "install", "--only", "main"
    
    # Copy the app to a proper location
    libexec.install "app.py", "pyproject.toml", "poetry.lock", ".env.example"
    
    # Create wrapper script
    (bin/"singalong-mdns-bridge").write_env_script(
      "#{libexec}/app.py",
      :PATH => "#{Formula["python@3.11"].opt_libexec}/bin:$PATH"
    )
  end
  
  def post_install
    # Create log directory
    (var/"log").mkpath
  end
  
  service do
    run "#{bin}/singalong-mdns-bridge"
    keep_alive true
    log_path "#{var}/log/singalong-mdns-bridge.log"
    error_log_path "#{var}/log/singalong-mdns-bridge.error.log"
    environment_variables(
      "NODE_HOST" => "localhost",
      "NODE_PORT" => "5002"
    )
  end
  
  test do
    # Simple test to verify installation
    assert_match "Singalong", shell_output("#{bin}/singalong-mdns-bridge --help 2>&1 || true")
  end
end
