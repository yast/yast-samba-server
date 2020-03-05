#!/usr/bin/env rspec
# encoding: utf-8
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
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "test_helper"

require "yast2/system_service"
require "yast2/compound_service"

Yast.import "Wizard"
Yast.import "SambaServer"
Yast.import "SambaService"

describe "SambaServerComplexInclude" do
  class TestComplexDialog
    include Yast::I18n
    include Yast::UIShortcuts

    def initialize
      Yast.include self, "samba-server/complex.rb"
    end
  end

  before do
    allow(Yast2::SystemService).to receive(:find).with(anything).and_return(service)
    allow(Yast2::CompoundService).to receive(:new).and_return(services)
    allow(services).to receive(:action).and_return(action)
    allow(services).to receive(:currently_active?).and_return(service_running)
  end

  let(:service) { instance_double("Yast2::SystemService", save: true, is_a?: true) }
  let(:services) { instance_double("Yast2::CompoundService", save: true) }
  let(:service_running) { false }
  let(:action) { :start }

  describe "#WriteDialog" do
    subject(:samba) { TestComplexDialog.new }

    let(:connected_users) { ["john", "jane"] }
    let(:service_on_boot) { false }

    let(:auto) { false }
    let(:commandline) { false }

    before do
      allow(Yast::Mode).to receive(:auto).and_return(auto)
      allow(Yast::Mode).to receive(:commandline).and_return(commandline)

      allow(Yast::Wizard).to receive(:RestoreHelp)

      allow(Yast::SambaService).to receive(:ConnectedUsers).and_return(connected_users)
      allow(Yast::SambaService).to receive(:GetServiceRunning).and_return(service_running)
      allow(Yast::SambaService).to receive(:GetServiceAutoStart).and_return(service_on_boot)

      allow(subject).to receive(:ProgressStatus).and_return(true)
    end

    shared_examples "old behavior" do
      it "does not save directly the system service" do
        expect(service).to_not receive(:save)

        samba.WriteDialog
      end

      it "calls SambaServer#Write" do
        expect(Yast::SambaServer).to receive(:Write)

        samba.WriteDialog
      end

      it "returns :next when SambaServer#Write is performed successfully" do
        allow(Yast::SambaServer).to receive(:Write).and_return(true)

        expect(samba.WriteDialog).to eq(:next)
      end

      it "returns :abort when SambaServer#Write fails" do
        allow(Yast::SambaServer).to receive(:Write).and_return(false)

        expect(samba.WriteDialog).to eq(:abort)
      end

      context "and service must be restarted" do
        context "but service is running and there are connected users" do
          let(:service_running) { true }
          let(:service_on_boot) { true }

          it "reloads the service instead" do
            expect(Yast::Report).to receive(:Message)

            samba.WriteDialog
          end
        end
      end
    end

    context "when running in command line" do
      let(:commandline) { true }

      include_examples "old behavior"
    end

    context "when running in AutoYaST mode" do
      let(:auto) { true }

      include_examples "old behavior"
    end

    context "when running in UI mode" do
      context "and fails written configuration" do
        before do
          allow(Yast::SambaServer).to receive(:Write).and_return(false)

          it "does not save the system service" do
            expect(services).to_not receive(:save)

            samba.WriteDialog
          end

          it "returns :abort" do
            expect(samba.WriteDialog).to eq(:abort)
          end
        end
      end

      context "and configuration is written" do
        before do
          allow(Yast::SambaServer).to receive(:Write).and_return(true)
        end

        it "saves the system service" do
          expect(services).to receive(:save)

          samba.WriteDialog
        end

        it "returns :next when sevice is saved successfully" do
          expect(samba.WriteDialog).to eq(:next)
        end

        it "returns :abort when fails saving the service" do
          allow(services).to receive(:save).and_return(false)

          expect(samba.WriteDialog).to eq(:abort)
        end

        context "and action is :restart" do
          let(:action) { :restart }

          context "but the service is already running" do
            let(:service_running) { true }
            let(:service_on_boot) { true }

            context "with connected users" do
              it "changes action to :reload" do
                expect(services).to receive(:reload)

                samba.WriteDialog
              end

              it "reports a message" do
                allow(services).to receive(:reload)
                expect(Yast::Report).to receive(:Message)

                samba.WriteDialog
              end
            end

            context "without connected users" do
              let(:connected_users) { [] }

              it "performs the requested action" do
                expect(services).to_not receive(:reload)

                samba.WriteDialog
              end
            end
          end
        end

        context "and action is NOT :restart" do
          let (:action) { :reload }

          context "and there are connected users" do
            it "does not report message" do
              expect(Yast::Report).to_not receive(:Message)

              samba.WriteDialog
            end
          end
        end
      end
    end
  end
end
