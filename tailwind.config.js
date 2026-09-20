/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,jsx}', './components/**/*.{js,jsx}'],
  theme: { extend: { colors: { pilgrimage: { 950: '#0f5132', 700: '#15803d', 100: '#dcfce7', 50: '#f0fdf4' } } } },
  plugins: []
}
