export default function usd(amount) {
  // The API gives us fixed-scale strings. Insert separators as text so even
  // the largest PostgreSQL balance displays without rounding in JavaScript.
  const [dollars, cents] = amount.split('.');
  return '$' + dollars.replace(/\B(?=(\d{3})+(?!\d))/g, ',') + '.' + cents;
}
