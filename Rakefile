require "yast/rake"

Yast::Tasks.submit_to :sle12sp5

Yast::Tasks.configuration do |conf|
  # lets ignore license check for now
  conf.skip_license_check << /.*/

  conf.install_locations["startup"] = Packaging::Configuration::YAST_LIB_DIR
end
