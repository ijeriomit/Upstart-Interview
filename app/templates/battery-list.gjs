import BatteryCard from '../components/battery-card';
import { Input } from '@ember/component';

<template>
  <label for="bat-search">
    Search by Name:
  </label>
  <Input
    id="bat-search"
    @type="text"
    @value={{@controller.searchText}}
    placeholder="Search batteries..."
  />
  <label for="bat-status">
    Filter by Status:
  </label>
  <select
    id="bat-status"
    {{on "change" @controller.updateStatus}}
    value={{@controller.selectedStatus}}
  >
    <option
      selected={{eq @controller.selectedStatus "all"}}
      value="all"
    >All</option>
    <option
      selected={{eq @controller.selectedStatus "online"}}
      value="online"
    >Online</option>
    <option
      selected={{eq @controller.selectedStatus "offline"}}
      value="offline"
    >Offline</option>
  </select>

  <label for="attention-required">
    Attention Required
  </label>
  <Input
    id="attention-required"
    @type="checkbox"
    @checked={{@controller.filterAttentionRequired}}
  />

  <h2>Battery Summary</h2>
  <p> Total: {{@controller.numberOfBatteries}} </p>
  <p> Offline: {{@controller.offlineCount}} </p>
  <p> Low Charge: {{@controller.lowChargeCount}} </p>

  {{#if (eq @controller.filteredBatteries.length 0)}}
    <div>No matching batteries.</div>
  {{else}}
    {{#each @controller.filteredBatteries key="id" as |battery|}}
      <BatteryCard
        @battery={{battery}}
        @onSave={{@controller.saveAlertThreshold}}
      />
    {{/each}}
  {{/if}}
</template>
