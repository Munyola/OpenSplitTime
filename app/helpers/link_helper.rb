# frozen_string_literal: true

module LinkHelper

  def reversed_sort_param(presenter, field, default = :asc)
    if default == :desc
      presenter.sort_hash[field] == :desc ? "#{field}" : "-#{field}"
    else
      presenter.sort_hash[field] == :asc ? "-#{field}" : "#{field}"
    end
  end

  def toggled_sort_param(presenter, field_1, field_2)
    presenter.sort_hash.has_key?(field_1) ? field_2 : field_1
  end

  def link_to_reversing_sort_heading(column_heading, field_name, existing_sort)
    new_sort = field_name.to_s == existing_sort.to_s ? "-#{field_name}" : field_name
    link_to_sort_heading(column_heading, new_sort)
  end

  def link_to_sort_heading(column_heading, sort_string)
    link_to column_heading, request.params.merge(sort: sort_string)
  end

  def link_to_select_gender(view_object, gender)
    link_to gender.titlecase, request.params.merge(filter: {gender: gender}),
            disabled: view_object.gender_text == gender
  end

  def link_to_select_display_style(view_object, display_style, title, options = {})
    class_text = options[:button] ? 'btn btn-md btn-primary' : ''
    link_to title, request.params.merge(display_style: display_style),
            disabled: view_object.display_style == display_style,
            class: class_text
  end
end
