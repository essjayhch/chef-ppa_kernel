use_inline_resources

def whyrun_supported?
  true
end

provides :ppa_kernel_version
def load_current_resource
  @new_resource.source_url = 'https://kernel.ubuntu.com/~kernel-ppa/mainline'
  @new_resource.source_prefix = "#{@new_resource.source_url}/v"\
                                "#{@new_resource.version}/"
  @new_resource.build_date = latest_build_date(@new_resource)
  @new_resource.image_file = filepath(@new_resource, 'image', 'amd64')
  @new_resource.headers_file = filepath(@new_resource, 'headers', 'amd64')
  @current_resource = @new_resource.dup
  @current_resource.build_date = current_build_date(@current_resource)
  @current_resource.uptodate =
    @current_resource.build_date == @new_resource.build_date
end

def latest_build_date(res)
  parse_build_date(res, latest_build_log(res))
end

def latest_build_log(res)
  download_last_build_log(res) unless ::File.exist? build_log_cache(res,
                                                                    'latest')

  ::IO.readlines(build_log_cache(res, 'latest')).last
end

def build_log_cache(res, release)
  cache_path("kernel-#{res.version}-#{release}_build_log")
end

def cache_path(suffix = nil)
  "#{Chef::Config[:file_cache_path]}/#{suffix}"
end

def download_last_build_log(res)
  # Retrieve it if it doesn't exist locally
  result = Net::HTTP.get(build_log_uri(res))
  ::File.write(build_log_cache(res, 'latest'), result.lines.last)
  result.lines.last
rescue
  log "Unable to retrieve build log, #{retry_remaining(3)} remaining retries"
  retry if retry?(3)
  # Throw a wobbly if it can't be retrieved
  Chef::Log.warn 'Unable to retrieve build log, not retrying'
  raise
end

def build_log_uri(res)
  URI "#{res.source_prefix}BUILD.LOG.amd64"
end

def filepath(res, type, geometry)
  "linux-#{type}-#{res.version}-#{zpad_vers(res)}-#{res.type}"\
  "_#{res.version}-#{zpad_vers(res)}.#{res.build_date}_#{geometry}.deb"
end

def zpad_vers(res)
  res.version.split('.').map { |s| format('%02i', s) }.join('')
end

def retry?(r)
  @count ||= 0
  @count += 1
  @count < r
end

def retry_remaining(r)
  @count ||= 0
  r - @count
end

def current_build_log(res)
  ::IO.readlines(build_log_cache(res, 'current')).last
rescue
  nil
end

def current_build_date(res)
  parse_build_date(res, current_build_log(res))
end

def parse_build_date(res, last_line)
  return unless last_line
  useful_bits = last_line.match(
    /linux_#{res.version}-#{zpad_vers(res)}\.(.*)_amd64\.tar\.gz/
  )
  useful_bits[1] if useful_bits
end

action :add do
  if @current_resource.uptodate
    Chef::Log.info "Kernel #{@new_resource} Already installed"\
                   ' and matches latest version'\
                   ' - nothing to do.'
    return
  else
    converge_by("Installing kernel version #{@new_resource}"\
                "with build date #{@new_resource.build_date}") do
      install_headers(@new_resource) if @new_resource.headers
      install_kernel(@new_resource)
      update_build_log_cache(@current_resource)
    end
  end
end

def install_kernel(res)
  download_kernel(res)
  dpkg_kernel(res)
  allow_reboot(res) if res.reboot_on_install
end

def download_kernel(r)
  remote_file cache_path(r.image_file) do
    source "#{r.source_prefix}/#{r.image_file}"
    action :create_if_missing
    notifies :install,
             "dpkg_package[linux-image-#{r.version}-#{r.type}-#{r.build_date}]",
             :immediately
  end
end

def dpkg_kernel(res)
  dpkg_package "linux-image-#{res.version}-#{res.type}-#{res.build_date}" do
    source cache_path(res.image_file)
    action :nothing
    notifies :reboot_now, 'reboot[new_kernel]' if res.reboot_on_install
  end
end

def allow_reboot(res)
  return unless res.reboot_on_install
  reboot 'new_kernel' do
    action :nothing
  end
end

def install_headers(res)
  download_headers(res)
  dpkg_headers(res)
end

def download_headers(res)
  download_raw_headers(res)
  download_generic_headers(res)
end

def package_version(r)
  "#{r.version}-#{r.type}-#{r.build_date}"
end

def download_generic_headers(r)
  remote_file cache_path(r.headers_file) do
    source "#{r.source_prefix}/#{r.headers_file}"
    action :create_if_missing
    notifies :install,
             "dpkg_package[linux-headers-#{package_version(r)}]",
             :immediately
  end
end

def raw_headers_file(res)
  res.headers_file.gsub('-generic', '').gsub('amd64', 'all')
end

def download_raw_headers(res)
  remote_file cache_path(raw_headers_file(res)) do
    source "#{res.source_prefix}/#{raw_headers_file(res)}"
    action :create_if_missing
    notifies :install,
             "dpkg_package[linux-headers-#{res.version}-#{res.build_date}]",
             :immediately
  end
end

def dpkg_headers(res)
  dpkg_raw_headers(res)
  dpkg_generic_headers(res)
end

def dpkg_raw_headers(res)
  dpkg_package "linux-headers-#{res.version}-#{res.build_date}" do
    source cache_path(raw_headers_file(res))
    action :nothing
  end
end

def dpkg_generic_headers(res)
  dpkg_package "linux-headers-#{res.version}-#{res.type}-#{res.build_date}" do
    source cache_path(res.headers_file)
    action :nothing
  end
end

def update_build_log_cache(res)
  ruby_block 'update_build_log_cache' do
    block do
      ::IO.write(
        cache_path("kernel-#{res.version}-current_build_log"),
        ::IO.read(
          cache_path("kernel-#{res.version}-latest_build_log")
        )
      )
    end
  end
end
