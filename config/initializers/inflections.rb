ActiveSupport::Inflector.inflections(:en) do |inflect|
  # inflect.plural /^(ox)$/i, '\1en'
  # inflect.singular /^(ox)en/i, '\1'
  # inflect.irregular 'person', 'people'
  # inflect.uncountable %w( fish sheep )

  inflect.singular 'Military Bases', 'Military Base'
  inflect.singular 'Seaplane Bases', 'Seaplane Base'

  inflect.human '1', 'one'
  inflect.human '2', 'two'
  inflect.human '3', 'three'
  inflect.human '4', 'four'
  inflect.human '5', 'five'
  inflect.human '6', 'six'
  inflect.human '7', 'seven'
end
