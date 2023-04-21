function maxAllowedMultiselect(obj, maxAllowedCount) {
    const selectedOptions = jQuery('#'+obj.id+' option:selected');
    if (selectedOptions.length > maxAllowedCount) {
      const lastSelectedOption = selectedOptions.last();
      lastSelectedOption.prop('selected', false);
    }
  }