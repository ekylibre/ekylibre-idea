# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2015 David Joulin, Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
module Backend
  class IdeaDiagnosticsController < Backend::BaseController
    manage_restfully
    before_action :notify_rotations, only: :new

    unroll

    list(order: { name: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :code, url: true
      t.column :auditor, label: :auditor
      t.column :state, label_method: 'state.tl'
      t.column :created_at
      t.column :stopped_at
    end

    def index
      @label = :new_diagnostic.tl
    end

    private

      def notify_rotations
        notify_warning(:notify_rotations.tl)
      end

  end
end
