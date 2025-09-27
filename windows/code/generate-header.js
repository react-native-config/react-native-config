const fs = require('fs')
const path = require('path')
const readline = require('readline')

const envFile = path.join(process.argv[2], '..', process.env['ENVFILE'] || '.env')
const outDir = path.join(process.argv[3], 'Generated Files')

console.log(`Generating files in ${outDir} from ${envFile} env file`)

if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir)
}

if (fs.existsSync(envFile)) {
  const vars = []
  const regex = /^\s*(?:export\s+|)([\w\d\.\-_]+)\s*=\s*['"]?(.*?)?['"]?\s*$/
  readline.createInterface({
    input: fs.createReadStream(envFile),
    console: false
  }).on('line', (line)=>{
    const matches = line.match(regex)
    if (matches)
      vars.push({key: matches[1], value: matches[2]})
  }).on('close', ()=> {
    generateFiles(vars)
  });
} else {
  console.warn(`waring: env file ${envFile} does not exit`)
  generateFiles([])
}

function generateFiles(vars) {
  // Native code
  let nativeCode = '';
  // React Native Module code: attribute-based constants block
  let rnCode = '';
  // Snippets for building a JS object with all constants
  let objectBuilder = '';
  nativeCode += '#include<string>\n'
  nativeCode += 'namespace ReactNativeConfig {\n'
  for (let {key, value} of vars) {
    const escaped = escapeString(value)
    nativeCode += `  inline static std::string ${key} = ${escaped};\n`
    rnCode += `REACT_CONSTANT(${key});\n`
    rnCode += `static inline const std::string ${key} = ${escaped};\n`;
    objectBuilder += `  obj["${key}"] = ReactNativeConfig::${key};\n`;
  }
  nativeCode +='}\n'
  updateFile(nativeCode, path.join(outDir, 'RNCConfigValues.h'))
  updateFile(rnCode, path.join(outDir, 'RNCConfigValuesModule.inc.g.h'))
  updateFile(objectBuilder, path.join(outDir, 'RNCConfigValuesObject.inc.g.h'))
}

// Escape the string so it will work with C++
// assume the string is UTF-8
const escapeRegex = /[a-zA-Z0-9`~!@#$%^&*()_=\-\+\{\}\];:'|<,.>?/\ ]/
function escapeString(string) {
  let escaped = '"';
  for (let i = 0;  i < string.length; ++i) {
    if (!string.substr(i,1).match(escapeRegex))
      escaped += `\\u${string.charCodeAt(i).toString(16)}`
    else
      escaped += string[i]
  }
  escaped += '"';
  return escaped;
}

// Make sure to not alter mtime of a file if its content did not change
function updateFile(content, filename) {
  if (!fs.existsSync(filename) || fs.readFileSync(filename) != content) {
    fs.writeFileSync(filename, content)
    console.log(`Written ${filename}`)
  } else {
    console.log(`Skipped ${filename} since content was not changed`)
  }
}
