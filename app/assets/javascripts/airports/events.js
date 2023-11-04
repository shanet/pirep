document.addEventListener('DOMContentLoaded', () => {
  if(!document.getElementById('event-form')) return;

  initRecurringToggle();
  initRecurringInterval();
  initRecurringCadence();
  initStartDate();
  setWeekOfMonthOptions(true);
}, {once: true});

function initRecurringToggle() {
  const recurringFields = document.getElementById('new-event-recurring');
  const recurringToggle = document.getElementById('new-event-recurring-toggle');

  // Show the recurring fields and set the hidden field to true/false so the controller knows if the event is recurring
  recurringToggle.addEventListener('change', () => {
    if(recurringToggle.checked) {
      recurringFields.classList.remove('d-none');
    } else {
      recurringFields.classList.add('d-none');
    }
  });
}

function initRecurringInterval() {
  const recurringInterval = document.getElementById('event_recurring_interval');
  const recurringCadence = document.getElementById('event_recurring_cadence');

  recurringInterval.addEventListener('change', () => {
    const value = parseInt(recurringInterval.value, 10);
    const options = recurringCadence.querySelectorAll('option');

    // Make each of the cadence options plural when the interval is greater than one, or singular when it is one
    for(let i=0; i<options.length; i++) {
      if(value > 1) {
        options[i].innerText = options[i].innerText.replace(/s?$/, 's');
      } else {
        options[i].innerText = options[i].innerText.replace(/s$/, '');
      }
    }
  });
}

function initRecurringCadence() {
  const recurringCadence = document.getElementById('event_recurring_cadence');
  const recurringWeekOfMonth = document.getElementById('event_recurring_week_of_month');

  // Only show the recurring week of month when the cadence is monthly or yearly
  recurringCadence.addEventListener('change', () => {
    if(['monthly', 'yearly'].indexOf(recurringCadence.value) !== -1) {
      setWeekOfMonthOptions();
      recurringWeekOfMonth.classList.remove('d-none');
    } else {
      recurringWeekOfMonth.classList.add('d-none');
    }
  });
}

function initStartDate() {
  const startDate = document.getElementById('event_start_date');

  startDate.addEventListener('change', () => {
    setWeekOfMonthOptions();
    copyStartDateToEndDate();
  });
}

function setWeekOfMonthOptions(setDefault) {
  const startDate = document.getElementById('event_start_date');
  const recurringWeekOfMonth = document.getElementById('event_recurring_week_of_month');

  // Clear the existing options
  recurringWeekOfMonth.innerHTML = '';
  recurringWeekOfMonth.disabled = false;

  // Add a placeholder if there is no start date yet
  if(startDate.value === '') {
    recurringWeekOfMonth.appendChild(createDisabledOption());
    recurringWeekOfMonth.disabled = true;
    return;
  }

  const date = new Date(startDate.value);

  createOptionForDayOfMonth(date, (setDefault ? recurringWeekOfMonth.dataset.default : null));
  createOptionsForWeekOfMonth(date, (setDefault ? recurringWeekOfMonth.dataset.default : null));
}

function createDisabledOption() {
  const option = document.createElement('option');
  option.innerText = '[select event start date]';
  return option;
}

function createOptionForDayOfMonth(date, defaultOption) {
  const recurringCadence = document.getElementById('event_recurring_cadence');
  const recurringWeekOfMonth = document.getElementById('event_recurring_week_of_month');

  const option = document.createElement('option');
  option.value = `day_${date.getDate()}`;
  option.selected = (option.value === defaultOption);

  switch(recurringCadence.value) {
    case 'monthly':
      option.innerText = `On the ${addOrdinalSuffix(date.getDate())}`;
      break;
    case 'yearly':
      option.innerText = `On ${dateToMonth(date)} ${addOrdinalSuffix(date.getDate())}`;
      break;
    default:
  }

  recurringWeekOfMonth.appendChild(option);
}

function createOptionsForWeekOfMonth(date, defaultOption) {
  const weekOfMonth = dateToWeekOfMonth(date);
  createOptionForWeekOfMonth(date, defaultOption, weekOfMonth);

  // If the date is on the 4th or 5th week of the month also show a "last week of" option
  if([4, 5].indexOf(weekOfMonth.week) !== -1) {
    createOptionForWeekOfMonth(date, defaultOption, {week: -1, label: 'last'});
  }
}

function createOptionForWeekOfMonth(date, defaultOption, weekOfMonth) {
  const recurringCadence = document.getElementById('event_recurring_cadence');
  const recurringWeekOfMonth = document.getElementById('event_recurring_week_of_month');

  const option = document.createElement('option');
  option.value = `week_${weekOfMonth.week}`;
  option.selected = (option.value === defaultOption);

  switch(recurringCadence.value) {
    case 'monthly':
      option.innerText = `On the ${weekOfMonth.label} ${dateToDayOfWeek(date)}`;
      break;
    case 'yearly':
      option.innerText = `On the ${weekOfMonth.label} ${dateToDayOfWeek(date)} of ${dateToMonth(date)}`;
      break;
    default:
  }

  recurringWeekOfMonth.appendChild(option);
}

function dateToDayOfWeek(date) {
  return date.toLocaleDateString('en-US', {weekday: 'long'});
}

function dateToMonth(date) {
  return date.toLocaleDateString('en-US', {month: 'long'});
}

function dateToWeekOfMonth(date) {
  const weekOfMonth = Math.ceil(date.getDate() / 7);

  return {
    week: weekOfMonth,
    label: ['first', 'second', 'third', 'fourth', 'fifth'][weekOfMonth - 1],
  };
}

function addOrdinalSuffix(number) {
  // This is kind of silly, but we only need to handle values 1-31 so why complicate the logic?
  if([1, 21, 31].indexOf(number) !== -1) return `${number}st`;
  if([2, 22].indexOf(number) !== -1) return `${number}nd`;
  if([3, 23].indexOf(number) !== -1) return `${number}rd`;

  return `${number}th`;
}

// Copy the start date to the end date when it's set as long as the end date is not already selected
function copyStartDateToEndDate() {
  const endDate = document.getElementById('event_end_date');
  if(endDate.value !== '') return;

  endDate.value = document.getElementById('event_start_date').value;
}
