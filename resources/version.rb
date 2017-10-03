actions :add
default_action :add

attribute :version, kind_of: String, name_property: true
attribute :type, kind_of: String, default: 'generic'
attribute :headers, kind_of: [TrueClass, FalseClass], default: true
attribute :reboot_on_install, kind_of: [TrueClass, FalseClass], default: false
attr_accessor :uptodate,
              :headers_file,
              :image_file,
              :build_date,
              :build_log_cache,
              :source_prefix,
              :source_url
