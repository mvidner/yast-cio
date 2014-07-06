# Copyright (c) 2014 SUSE LLC.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
# Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact Novell about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require "yast"

class Widget
  # @return a Term for Yast::UI.OpenDialog
  def to_term
    raise NotImplementedError
  end

  # @api private
  def term(*args)
    Yast::Term.new(*args)
  end
end

class PushButton < Widget
  attr_reader :id, :label
  def initialize(id, label)
    @id = id
    @label = label
  end

  def to_term
    term(:PushButton, term(:id, id), label)
  end
end

class Dialog
  def run
    open_dialog or raise "Failed to create dialog"
    begin
      controller_loop
    ensure
      close_dialog
    end
  end

  def open_dialog
    Yast::UI.OpenDialog dialog_content
  end

  def dialog_content
    raise NotImplementedError
  end

  def close_dialog
    Yast::UI.CloseDialog
  end
end
