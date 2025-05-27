const fs = require('fs');
const path = require('path');
const https = require('https');

// Font variants to download
const fontVariants = [
  { name: 'Poppins-Regular.ttf', url: 'https://fonts.gstatic.com/s/poppins/v20/pxiEyp8kv8JHgFVrJJfecg.woff2' },
  { name: 'Poppins-Medium.ttf', url: 'https://fonts.gstatic.com/s/poppins/v20/pxiByp8kv8JHgFVrLGT9Z1xlFQ.woff2' },
  { name: 'Poppins-SemiBold.ttf', url: 'https://fonts.gstatic.com/s/poppins/v20/pxiByp8kv8JHgFVrLEj6Z1xlFQ.woff2' },
  { name: 'Poppins-Bold.ttf', url: 'https://fonts.gstatic.com/s/poppins/v20/pxiByp8kv8JHgFVrLCz7Z1xlFQ.woff2' }
];

const fontsDir = path.join(__dirname, 'assets', 'fonts');

// Create fonts directory if it doesn't exist
if (!fs.existsSync(fontsDir)) {
  fs.mkdirSync(fontsDir, { recursive: true });
}

console.log('Downloading Poppins font files from Google Fonts...');
console.log(`Font directory: ${fontsDir}`);

// Function to download a file
function downloadFile(url, destination) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(destination);
    
    https.get(url, (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`Failed to download file, status code: ${response.statusCode}`));
        return;
      }
      
      response.pipe(file);
      
      file.on('finish', () => {
        file.close(resolve);
        console.log(`Downloaded: ${destination}`);
      });
    }).on('error', (err) => {
      fs.unlink(destination, () => {}); // Delete the file if there was an error
      reject(err);
    });
  });
}

// Download all font variants
async function downloadAllFonts() {
  const promises = fontVariants.map(font => {
    const fontPath = path.join(fontsDir, font.name);
    return downloadFile(font.url, fontPath);
  });
  
  try {
    await Promise.all(promises);
    console.log('All fonts downloaded successfully!');
    console.log('You can now run the app with flutter run');
  } catch (error) {
    console.error('Error downloading fonts:', error.message);
  }
}

downloadAllFonts(); 