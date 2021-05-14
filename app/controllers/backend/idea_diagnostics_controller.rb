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

    unroll

    list(order: { name: :desc }) do |t|
      t.column :name, url: true
      t.column :code, url: true
      t.column :updater
      t.column :state
      t.column :started_on
    end

    def index
      @label = if IdeaDiagnostic.find_by(campaign_id: current_campaign.id).present?
                 :new_diagnostic.tl
               else
                 :new_diagnostic_name.tl(name: current_campaign.name)
               end
    end

  end
end
