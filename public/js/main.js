function maxAllowedMultiselect(obj, maxAllowedCount) {
    const selectedOptions = jQuery('#'+obj.id+' option:selected');
    
    if (selectedOptions.length > maxAllowedCount) {
      const lastSelectedOption = selectedOptions.last();
      lastSelectedOption.prop('selected', false);
    }
  }

function addQuotesToArray(array) {
  let pokemons = array
  const strArray = JSON.stringify(pokemons)
  return strArray
}

function parsePokemonArray(jsonStrings) {
  const jsonFixed = jsonStrings.map(str => str.replace(/=>/g, ':'));
  const pokemons = jsonFixed.map(str => JSON.parse(str));
  return pokemons;
}

function fixArray(arr) {
  const fixedArr = arr.map(str => {
    const replaced = str.replace(/=>/g, ':').replace(/nil/g, 'null');
    return JSON.parse(replaced);
  });
  return fixedArr;
}

function removeQuotesFromArray(array) {
  const jsonString = array
  const pokemonArray = JSON.parse(jsonString);
  return pokemonArray
}