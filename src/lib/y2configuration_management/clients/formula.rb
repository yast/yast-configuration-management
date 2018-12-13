# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "yast"
require "y2configuration_management/salt/formula"
require "y2configuration_management/salt/formula_sequence"
require "configuration_management/cfa/salt_top"

module Y2ConfigurationManagement
  module Clients
    # Client to configure formulas
    class Formula < Yast::Client
      include Yast::Logger
      extend Yast::I18n

      # @return [Array<Y2ConfigurationManagement::Salt::Formula>]
      attr_accessor :formulas
      # @return [String]
      attr_reader :states_root, :formulas_root, :pillar_root

      # Constructor
      def initialize
        textdomain "configuration_management"
      end

      def main
        configure_directories
        read_formulas
        start_workflow
        write_formulas
      end

    private

      def start_workflow
        Y2ConfigurationManagement::Salt::FormulaSequence.new(formulas).run
      end

      def configure_directories
        @states_root, @formulas_root, @pillar_root = Yast::WFM.Args()
        @states_root ||= Y2ConfigurationManagement::Salt::Formula::BASE_DIR + "/states"
        @formulas_root ||= Y2ConfigurationManagement::Salt::Formula.formula_directories
        @pillar_root ||= Y2ConfigurationManagement::Salt::Formula::DATA_DIR + "/pillar"
      end

      def read_formulas
        self.formulas = Y2ConfigurationManagement::Salt::Formula.all(formulas_root)
        formulas.each { |f| f.pillar = pillar_for(f) }
      end

      def write_formulas
        [pillar_root, states_root].each do |path|
          ::FileUtils.mkdir_p(path) unless File.exist?(path)
          top = Yast::ConfigurationManagement::CFA::SaltTop.new(path: File.join(path, "top.sls"))
          top.load
          top.add_states(formulas.select(&:enabled?).map(&:id))
          top.save
        end
      end

      def pillar_for(formula)
        pillar_file = File.join(pillar_root, "#{formula.id}.sls")
        pillar = Y2ConfigurationManagement::Salt::Pillar.new(data: {}, path: pillar_file)
        pillar.load
        pillar
      end
    end
  end
end
