function maxAllowedMultiselect(obj, maxAllowedCount) {
    const selectedOptions = jQuery('#'+obj.id+' option:selected');
    
    if (selectedOptions.length > maxAllowedCount) {
      const lastSelectedOption = selectedOptions.last();
      lastSelectedOption.prop('selected', false);
    }
  }

function addQuotesToArray(array) {
    const strArray = JSON.stringify(array);
    return strArray.replace(/\[/g, "\"[").replace(/\]/g, "]\"");
}