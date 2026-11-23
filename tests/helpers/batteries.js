export function makeBatteries() {
  return [
    { id: '1', name: 'Home', chargePercent: 82, status: 'online', alertThreshold: 20 },
    { id: '2', name: 'Garage', chargePercent: 45, status: 'charging', alertThreshold: 20 },
    { id: '3', name: 'Cabin', chargePercent: 12, status: 'offline', alertThreshold: 20 },
  ];
}
