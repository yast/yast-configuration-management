# encoding: utf-8

# Copyright (c) [2019] SUSE LLC
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

module Y2ConfigurationManagement
  module Salt
    # This module is meant to include methods to work with form element specifications.
    module FormElementHelpers
      # Determines which part of the given spec refers to a form element
      #
      # Usually, all elements whose name starts with `$` are supposed to be metadata, except the
      # special `$key` element which is considered an form input.
      #
      # @param spec [Hash] form element specification
      # @return [Array<Hash>]
      def form_elements_in(spec)
        spec.select { |k, _v| !k.start_with?("$") || k == "$key" }
      end
    end
  end
end
