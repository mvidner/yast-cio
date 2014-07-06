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
    include Yast::UIShortcuts
    include Yast::I18n

    def self.run
      Yast.import "UI"

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
      Yast::UI.ChangeWidget(:channels_table, :Items, channels_items)
    end

    def controller_loop
      while true do
        input = Yast::UI.UserInput
        case input
        when :ok, :cancel
          return :ok
        when :filter_text
          redraw_channels
        when :clear
          Yast::UI.ChangeWidget(:channels_table, :SelectedItems, [])
        when :select_all
          Yast::UI.ChangeWidget(:channels_table, :SelectedItems, prefiltered_channels.map(&:device))
        when :block
          block_channels
          read_channels
          redraw_channels
        when :unban
          devices = UnbanDialog.run
          Yast.y2milestone("Going to unblock devices #{devices.inspect}")
          next unless devices

          unban_channels devices
          read_channels
          redraw_channels
        else
          raise "Unknown action #{input}"
        end
      end
    end

    def block_channels
      devices = Yast::UI.QueryWidget(:channels_table, :SelectedItems)
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
      Heading(_("Available Input/Output Channels"))
    end

    def channels_table
      Table(
        Id(:channels_table),
        Opt(:multiSelection),
        Header(_("Device"), _("Used")),
        channels_items
      )
    end

    def channels_items
      prefiltered_channels.map do |channel|
        Item(
          Id(channel.device),
          channel.device,
          channel.used? ? _("yes") : _("no")
        )
      end
    end

    def prefiltered_channels
      filter = Yast::UI.QueryWidget(:filter_text, :Value)

      # filter can be empty if dialog is not yet created
      return @channels if !filter || filter.empty?

      @channels.select do |channel|
        channel.device.include? filter
      end
    end

    EMPTY_LABEL = ""
    def action_buttons
      VBox.new(
        Label(_("Filter channels")),
        InputField.new(:filter_text, :notify, EMPTY_LABEL),
        PushButton.new(:select_all, _("&Select All")),
        PushButton.new(:clear, _("&Clear selection")),
        PushButton.new(:block, _("&Blacklist Selected Channels")),
        PushButton.new(:unban, _("&Unban Channels")),
      )
    end

    def ending_buttons
      PushButton.new(:ok, _("&Exit"))
    end
  end
end
