# Efossils -- a multirepository for fossil-scm
# Copyright (C) 2018  Jovany Leandro G.C <bit4bit@riseup.net>
#
# This file is part of Efossils.
#
# Efossils is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Efossils is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

defmodule Efossils.Accounts.Repository do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Efossils.License
  
  @licenses [
    {:agpl1, %License{name: "AGPL 1",
                      uri: "https://gnu.org/licenses/agpl.html",
                      comment: "https://gnu.org/licenses/why-affero-gpl.html"}},
    {:agpl3, %License{name: "AGPL 3",
                      uri: "https://gnu.org/licenses/agpl.html",
                      comment: "https://gnu.org/licenses/why-affero-gpl.html"}},
    {:"agpl3+", %License{name: "AGPL 3+",
                         uri: "https://gnu.org/licenses/agpl.html",
                         comment: "https://gnu.org/licenses/why-affero-gpl.html"}},
    {:"asl1.1", %License{name: "ASL 1.1",
                         uri: "http://directory.fsf.org/wiki/License:Apache1.1",
                         comment: "https://www.gnu.org/licenses/license-list#apache1"}},
    {:"asl2.0", %License{name: "ASL 2.0",
                         uri: "http://directory.fsf.org/wiki/License:Apache2.0",
                         comment: "https://www.gnu.org/licenses/license-list#apache2"}},
    {:"boost1.0", %License{name: "Boost 1.0",
                           uri: "http://directory.fsf.org/wiki/License:Boost1.0",
                           comment: "https://www.gnu.org/licenses/license-list#boost"}},
    {:"bsd-2", %License{name: "FreeBSD",
                        uri: "http://directory.fsf.org/wiki/License:FreeBSD",
                        comment: "https://www.gnu.org/licenses/license-list#FreeBSD"}},
    {:"bsd-3", %License{name: "Modified BSD",
                        uri: "http://directory.fsf.org/wiki/License:BSD_3Clause",
                        comment: "https://www.gnu.org/licenses/license-list#ModifiedBSD"}},
    {:"bsd-4", %License{name: "Original BSD",
                        uri: "http://directory.fsf.org/wiki/License:BSD_4Clause",
                        comment: "https://www.gnu.org/licenses/license-list#OriginalBSD"}},
    {:cc0, %License{name: "CC0",
                    uri: "http://creativecommons.org/licenses/by-sa/4.0/",
                    comment: "http://www.gnu.org/licenses/license-list.html#CC0"}},

    {:"cc-by-sa4.0", %License{name: "CC-BY-SA 4.0",
                              uri: "http://creativecommons.org/licenses/by-sa/3.0/",
                              comment: "Creative Commons Attribution-ShareAlike 4.0 International"}},
    {:"cc-by-sa3.0", %License{name: "CC-BY-SA 3.0",
                              uri: "http://creativecommons.org/licenses/by-sa/3.0/",
                              comment: "Creative Commons Attribution-ShareAlike 3.0 Unported"}},
    {:"cc-by-sa2.0", %License{name: "CC-BY-SA 2.0",
                              uri: "http://creativecommons.org/licenses/by-sa/2.0/",
                              comment: "Creative Commons Attribution-ShareAlike 2.0 Generic"}},
    {:"cc-by4.0", %License{name: "CC-BY 4.0",
                           uri: "http://creativecommons.org/licenses/by/4.0/",
                           comment: "Creative Commons Attribution 4.0 Unported"}},
    {:"cc-by3.0", %License{name: "CC-BY 3.0",
                           uri: "http://creativecommons.org/licenses/by/3.0/",
                           comment: "Creative Commons Attribution 3.0 Unported"}},
    {:"cc-by2.0", %License{name: "CC-BY 2.0",
                           uri: "http://creativecommons.org/licenses/by/2.0/",
                           comment: "Creative Commons Attribution 2.0 Generic"}},
    {:"cc-sampling-plus-1.0", %License{name: "CC-Sampling+ 1.0",
                                       uri: "https://creativecommons.org/licenses/sampling+/1.0",
                                       comment: "Creative Commons Sampling Plus 1.0"}},
    {:"cddl1.0", %License{name: "CDDL 1.0",
                          uri: "http://directory.fsf.org/wiki/License:CDDLv1.0",
                          comment: "https://www.gnu.org/licenses/license-list#CDDL"}},
    {:"cddl1.1", %License{name: "CDDL 1.1",
                          uri: "https://oss.oracle.com/licenses/CDDL+GPL-1.1",
                          comment: "https://www.gnu.org/licenses/license-list#CDDL"}},
    {:cecill, %License{name: "CeCILL",
                       uri: "http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.html",
                       comment: "https://www.gnu.org/licenses/license-list.html#CeCILL"}},
    {:"artistic2.0", %License{name: "Artistic License 2.0",
                              uri: "http://www.perlfoundation.org/artistic_license_2_0",
                              comment: "http://www.gnu.org/licenses/license-list.html#ArtisticLicense2"}},
    {:"clarified-artistic", %License{name: "Clarified Artistic",
                                     uri: "http://gianluca.dellavedova.org/2011/01/03/clarified-artistic-license/",
                                     comment: "https://www.gnu.org/licenses/license-list.html#ArtisticLicense2"}},
    {:"copyleft-next", %License{name: "copyleft-next",
                                uri: "https://raw.github.com/richardfontana/copyleft-next/master/Releases/copyleft-next-0.3.0",
                                comment: "GPL-compatible copyleft license"}},
    {:"cpl1.0", %License{name: "CPL 1.0",
                         uri: "http://directory.fsf.org/wiki/License:CPLv1.0",
                         comment: "https://www.gnu.org/licenses/license-list#CommonPublicLicense10"}},
    {:"epl1.0", %License{name: "EPL 1.0",
                         uri: "http://directory.fsf.org/wiki/License:EPLv1.0",
                         comment: "https://www.gnu.org/licenses/license-list#EPL"}},
    {:expat, %License{name: "Expat",
                      uri: "http://directory.fsf.org/wiki/License:Expat",
                      comment: "https://www.gnu.org/licenses/license-list.html#Expat"}},
    {:freetype, %License{name: "Freetype",
                         uri: "http://directory.fsf.org/wiki/License:Freetype",
                         comment: "https://www.gnu.org/licenses/license-list.html#freetype"}},
    {:giftware, %License{name: "Giftware",
                         uri: "http://liballeg.org/license.html",
                         comment: "The Allegro 4 license"}},
    {:gpl1, %License{name: "GPL 1",
                     uri: "https://www.gnu.org/licenses/old-licenses/gpl-1.0.html",
                     comment: false}},
    {:"gpl1+", %License{name: "GPL 1+",
                        uri: "https://www.gnu.org/licenses/old-licenses/gpl-1.0.html",
                        comment: false}},
    {:gpl2, %License{name: "GPL 2",
                     uri: "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html",
                     comment: "https://www.gnu.org/licenses/license-list#GPLv2"}},
    {:"gpl2+", %License{name: "GPL 2+",
                        uri: "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html",
                        comment: "https://www.gnu.org/licenses/license-list#GPLv2"}},
    {:gpl3, %License{name: "GPL 3",
                     uri: "https://www.gnu.org/licenses/gpl.html",
                     comment: "https://www.gnu.org/licenses/license-list#GNUGPLv3"}},
    {:"gpl3+", %License{name: "GPL 3+",
                        uri: "https://www.gnu.org/licenses/gpl.html",
                        comment: "https://www.gnu.org/licenses/license-list#GNUGPLv3"}},
    {:"gfl1.0", %License{name: "GUST font license 1.0",
                         uri: "http://www.gust.org.pl/projects/e-foundry/licenses/GUST-FONT-LICENSE.txt",
                         comment: "https://www.gnu.org/licenses/license-list#LPPL-1.3a"}},
    {:"fdl1.1+", %License{name: "FDL 1.1+",
                          uri: "https://www.gnu.org/licenses/fdl-1.1",
                          comment: "https://www.gnu.org/licenses/license-list#FDL"}},
    {:"fdl1.2+", %License{name: "FDL 1.2+",
                          uri: "https://www.gnu.org/licenses/fdl-1.2",
                          comment: "https://www.gnu.org/licenses/license-list#FDL"}},
    {:"fdl1.3+", %License{name: "FDL 1.3+",
                          uri: "https://www.gnu.org/licenses/fdl.html",
                          comment: "https://www.gnu.org/licenses/license-list#FDL"}},
    {:"opl1.0+", %License{name: "Open Publication License 1.0 or later",
                          uri: "http://opencontent.org/openpub/",
                          comment: "https://www.gnu.org/licenses/license-list#OpenPublicationL"}},
    {:isc, %License{name: "ISC",
                    uri: "http://directory.fsf.org/wiki/License:ISC",
                    comment: "https://www.gnu.org/licenses/license-list.html#ISC"}},
    {:ijg, %License{name: "IJG",
                    uri: "http://directory.fsf.org/wiki/License:JPEG",
                    comment: "https://www.gnu.org/licenses/license-list#ijg"}},
    {:"lgpl2.0", %License{name: "LGPL 2.0",
                          uri: "https://www.gnu.org/licenses/old-licenses/lgpl-2.0.html",
                          comment: "https://www.gnu.org/licenses/why-not-lgpl.html"}},
    {:"lgpl2.0+", %License{name: "LGPL 2.0+",
                           uri: "https://www.gnu.org/licenses/old-licenses/lgpl-2.0.html",
                           comment: "https://www.gnu.org/licenses/why-not-lgpl.html"}},
    {:"lgpl2.1", %License{name: "LGPL 2.1",
                          uri: "https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html",
                          comment: "https://www.gnu.org/licenses/license-list#LGPLv2.1"}},
    {:"lgpl2.1+", %License{name: "LGPL 2.1+",
                           uri: "https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html",
                           comment: "https://www.gnu.org/licenses/license-list#LGPLv2.1"}},
    {:"lgpl3", %License{name: "LGPL 3",
                        uri: "https://www.gnu.org/licenses/lgpl.html",
                        comment: "https://www.gnu.org/licenses/license-list#LGPLv3"}},
    {:"lgpl3+", %License{name: "LGPL 3+",
                         uri: "https://www.gnu.org/licenses/lgpl.html",
                         comment: "https://www.gnu.org/licenses/license-list#LGPLv3"}},
    {:"mpl1.0", %License{name: "MPL 1.0",
                         uri: "http://www.mozilla.org/MPL/1.0/",
                         comment: "https://www.gnu.org/licenses/license-list.html#MPL"}},
    {:"mpl1.1", %License{name: "MPL 1.1",
                         uri: "http://directory.fsf.org/wiki/License:MPLv1.1",
                         comment: "https://www.gnu.org/licenses/license-list#MPL"}},
    {:"mpl2.0", %License{name: "MPL 2.0",
                         uri: "http://directory.fsf.org/wiki/License:MPLv2.0",
                         comment: "https://www.gnu.org/licenses/license-list#MPL-2.0"}},
    {:"x11", %License{name: "X11",
                      uri: "https://directory.fsf.org/wiki/License:X11",
			                comment: "https://www.gnu.org/licenses/license-list.html#X11License"}},
    {:"custom", %License{name: "CUSTOM",
                         uri: "", comment: "See COPYING or LICENSE for details"}},
    
  ]
  def licenses, do: @licenses

  
  schema "repositories" do
    field :description, :string
    field :is_private, :boolean, default: false
    field :lower_name, :string
    field :name, :string
    field :num_forks, :integer
    field :num_stars, :integer
    field :num_watchers, :integer
    field :size, :integer
    field :website, :string
    field :license, :string
    field :fossil_extras, :map
    belongs_to :base_repository, Efossils.Accounts.Repository
    belongs_to :owner, Efossils.User
    has_many :collaborations, Efossils.Accounts.Collaboration
    has_many :collaborations_users,  through: [:collaborations, :user]
    timestamps()
  end

  @doc false
  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:lower_name, :name, :description, :website, :num_watchers, :num_stars, :num_forks, :is_private, :size, :license, :owner_id, :fossil_extras])
    |> Efossils.Utils.build_lower_name()
    |> cast_assoc(:owner)
    |> cast_assoc(:base_repository)
    |> validate_required([:name, :is_private])
    |> unique_constraint(:name, name: :repositories_owner_id_name_index)
  end

  @doc false
  def prepare_attrs(attrs) do
    attrs
    |> Map.put("lower_name", Efossils.Utils.sanitize_name(attrs["name"]))
  end

  @doc false
  def validate_max_repositories(changeset) do
    case fetch_field(changeset, :owner_id) do
      {_, owner_id} ->
        user = Efossils.Repo.one(from u in Efossils.User,
        select: [u.max_repo_creation, u.num_repos],
        where: u.id == ^owner_id)
        case user do
          nil -> changeset
          [max_repo_creation, num_repos] ->
            if max_repo_creation > 0 and (num_repos + 1) > max_repo_creation do
              add_error(changeset, :owner_id, "sorry, get limit please contact us")
            else
              changeset
            end
        end
    end
  end
  
end
