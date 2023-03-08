require 'application_system_test_case'

class AirportsAnnotationsTest < ApplicationSystemTestCase
  include ActionView::Helpers::NumberHelper

  setup do
    @airport = create(:airport, annotations: [])
    @annotated_airport = create(:airport)
    @label = 'Parking'
  end

  test 'add annotation' do
    visit_airport(@airport)
    start_editing_annotations

    # Assert that the help text is shown in editing mode
    assert_selector '#annotations-help'

    # Add an annotation, fill in the textfield, and save it
    find('#airport-map canvas').click
    find('.annotation input[type="text"]').set(@label)
    find('.annotation button.save').click

    # Wait for the saved text to be shown and then check that the backend saved the new annotation
    assert_equal @label, find('.annotation .label').text, 'Annotation\'s label not set to entered value'
    assert_selector '.airport-annotations-saved'
    assert_equal @label, @airport.reload.annotations.first['label'], 'Annotation not saved'

    # Re-enter editing mode for the annotation and test dragging it to a new position
    find('.annotation .label').click
    move_annotation(100, 100)
    stop_editing_annotations

    # Check that the annotation's latitude and longitude were moved in the right directions by the drag
    previous_annotation = @airport.annotations.first
    assert previous_annotation['latitude'] > @airport.reload.annotations.first['latitude'], 'Annotation latitude not updated when moved'
    assert previous_annotation['longitude'] < @airport.reload.annotations.first['longitude'], 'Annotation longitude not updated when moved'

    # We should not be able to move outside of editing mode (start/stop editing mode to trigger a save event and check if the backend annotations changed)
    move_annotation(100, 100)
    start_editing_annotations
    stop_editing_annotations
    assert_equal @airport.annotations, @airport.reload.annotations

    # Test deleting the annotation
    start_editing_annotations
    find('.annotation button.delete').click

    assert_no_selector('annotation')
    assert_selector '.airport-annotations-saved'
    assert_equal [], @airport.reload.annotations, 'Deleted annotation not removed from backend'
  end

  test 'restore and edit annotations' do
    visit_airport(@annotated_airport)

    assert_selector '.annotation', count: @annotated_airport.annotations.count

    # All annotations should be in editing mode when enabled
    start_editing_annotations
    assert_selector '.annotation.editing', count: @annotated_airport.annotations.count

    # Saving one annotation should leave the remaining ones in editing mode
    find('.annotation button.save', match: :first).click
    assert_selector '.annotation.editing', count: @annotated_airport.annotations.count - 1

    # All annotations should be taken out of editing mode when the toggle switch is flipped
    stop_editing_annotations
    assert_no_selector '.annotation.editing'
  end

  test 'ignores invalid annotations' do
    airport = create(:airport, annotations: [{label: 'Blackhole', latitude: 999, longitude: 999}])

    visit_airport(airport)
    assert_no_selector '.annotation'
  end

private

  def visit_airport(airport)
    visit airport_path(airport)
    wait_for_map_ready('airport-map')
  end

  def start_editing_annotations
    find('#annotations-editing').click
    assert_selector '#airport-map.editing'
  end

  def stop_editing_annotations
    find('#annotations-editing').click
    assert_selector '.airport-annotations-saved'
    assert_no_selector '#airport-map.editing'
  end

  def move_annotation(delta_x, delta_y)
    annotation_icon = find('#airport-map .mapboxgl-marker')

    # Scroll to the annotation so we can move it down without going out of the viewport of the browser since Capybara will only drag within the viewport
    scroll_to(annotation_icon)

    page.driver.browser.action.move_to(annotation_icon.native).click_and_hold.move_by(delta_x, delta_y).release.perform
  end
end
