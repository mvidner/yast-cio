#! rspec
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


require_relative "spec_helper"

require "iochannel/unban_dialog"

describe IOChannel::UnbanDialog do
  def mock_dialog data={}
    data[:input] ||= :ok
    data[:channel_range] ||= ""

    data[:input] = [data[:input]] unless data[:input].is_a? Array

    ui = double("Yast::UI")
    stub_const("Yast::UI", ui)

    expect(ui).to receive(:OpenDialog).
      and_return(true)

    expect(ui).to receive(:CloseDialog).
      and_return(true)

    expect(ui).to receive(:UserInput).
      and_return(*data[:input])

    allow(ui).to receive(:QueryWidget).
      with(:channel_range, :Value).
      and_return(data[:channel_range])
  end

  it "return a simple value" do
    mock_dialog :input => :ok, :channel_range => "0.0.0000"

    expect(IOChannel::UnbanDialog.run).to eq ["0.0.0000"]
  end

  it "return nil if user closes window" do
    mock_dialog :input => :cancel

    expect(IOChannel::UnbanDialog.run).to eq nil
  end
end
