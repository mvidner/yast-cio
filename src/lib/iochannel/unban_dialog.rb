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

require "iochannel/channels"
require "iochannel/channel_range"
require "widgets"
require "yast"

module IOChannel
  class UnbanDialog < Dialog
    include Yast::I18n

    def self.run
      Yast.import "UI"
      Yast.import "Label"

      dialog = UnbanDialog.new
      dialog.run
    end

    def initialize
      textdomain "cio"
    end

  private
    def ok_handler
      channel_range_value = Yast::UI.QueryWidget(:channel_range, :Value)
      range = ChannelRange.from_string channel_range_value
      exit(range.matching_channels)
    rescue InvalidRangeValue => e
      invalid_range_message(e.value)
    end

    def invalid_range_message value
      # TRANSLATORS: %s stands for the smallest snippet inside which we detect syntax error
      msg = _("Specified range is invalid. Wrong value is inside snippet '%s'") % value
      widget = Label.new(msg)
      Yast::UI.ReplaceWidget(:message, widget.to_term)
    end

    def dialog_content
      VBox.new(
        heading,
        *unban_content,
        ending_buttons
      )
    end

    def ending_buttons
      HBox.new(
        PushButton.new(:ok, Yast::Label.OKButton) { ok_handler },
        PushButton.new(:cancel, Yast::Label.CancelButton) { exit nil }
      )
    end

    def heading
      Heading.new(_("Unban Input/Output Channels"))
    end

    def unban_content
      [
        Label.new(_("List of ranges of channels to unban separated by comma.\n"+
          "Range can be channel, part of channel which will be filled to zero or range specified with dash.\n"+
          "Example value: 0.0.0001, AA00, 0.1.0100-200")),
        ReplacePoint.new(:message, Empty.new),
        InputField.new(:channel_range, _("Ranges to Unban."), "")
      ]
    end
  end
end
