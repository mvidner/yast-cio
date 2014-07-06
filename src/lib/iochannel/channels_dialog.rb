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
require "iochannel/unban_dialog"
require "widgets"
require "yast"

module IOChannel
  class ChannelsDialog < Dialog
    include Yast::I18n

    def self.run
      dialog = ChannelsDialog.new
      dialog.run
    end

    def initialize
      textdomain "cio"

      read_channels
    end

  private
    DEFAULT_SIZE_OPT = Yast::Term.new(:opt, :defaultsize)

    def options
      [DEFAULT_SIZE_OPT]
    end

    def read_channels
      @channels = Channels.allowed
    end

    def redraw_channels
      @channels_table.items = channels_items
    end

    def global_handler(input)
        case input
        when :cancel
          exit :ok
        when :filter_text
          redraw_channels
        when :clear
          @channels_table.value = []
        when :select_all
          @channels_table.value = prefiltered_channels.map(&:device)
        when :block
          block_channels
          read_channels
          redraw_channels
        when :unban
          devices = UnbanDialog.run
          Yast.y2milestone("Going to unblock devices #{devices.inspect}")
          return unless devices

          unban_channels devices
          read_channels
          redraw_channels
        else
          raise "Unknown action #{input}"
        end
    end

    def block_channels
      devices = @channels_table.value
      channels = Channels.new(devices.map {|d| Channel.new(d) })

      Yast.y2milestone("Going to block channels #{channels.inspect}")
      channels.block
    end

    def unban_channels devices
      channels = Channels.new(devices.map{ |c| Channel.new c })
      channels.unblock
    end

    def dialog_content
      VBox.new(
        headings,
        HBox.new(
          channels_table,
          action_buttons
        ),
        ending_buttons
      )
    end

    def headings
      Heading.new(_("Available Input/Output Channels"))
    end

    def channels_table
      @channels_table = Table.new(
        :channels_table,
        :multiSelection,
        [_("Device"), _("Used")],
        channels_items
      )
    end

    def channels_items
      prefiltered_channels.map do |channel|
        Yast::Term.new(:item, 
          Yast::Term.new(:id, channel.device),
          channel.device,
          channel.used? ? _("yes") : _("no")
        )
      end
    end

    def prefiltered_channels
      if ! @filter_text         # dialog not yet created
        return @channels
      end
      filter = @filter_text.value

      return @channels if filter.empty?

      @channels.select do |channel|
        channel.device.include? filter
      end
    end

    EMPTY_LABEL = ""
    def action_buttons
      VBox.new(
        Label.new(_("Filter channels")),
        @filter_text = InputField.new(:filter_text, :notify, EMPTY_LABEL),
        PushButton.new(:select_all, _("&Select All")),
        PushButton.new(:clear, _("&Clear selection")),
        PushButton.new(:block, _("&Blacklist Selected Channels")),
        PushButton.new(:unban, _("&Unban Channels")),
      )
    end

    def ending_buttons
      PushButton.new(:ok, _("&Exit")) { exit :ok }
    end
  end
end
