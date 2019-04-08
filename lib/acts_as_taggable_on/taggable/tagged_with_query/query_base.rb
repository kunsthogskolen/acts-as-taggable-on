module ActsAsTaggableOn
  module Taggable
    module TaggedWithQuery
      class QueryBase
        def initialize(
          taggable_model, tag_model, tagging_model, tag_list, options
        )
          @taggable_model = taggable_model
          @tag_model      = tag_model
          @tagging_model  = tagging_model
          @tag_list       = tag_list
          @options        = options
        end

        private

        attr_reader :taggable_model, :tag_model, :tagging_model, :tag_list,
                    :options

        def taggable_arel_table
          @taggable_arel_table ||= taggable_model.arel_table
        end

        def tag_arel_table
          @tag_arel_table ||= tag_model.arel_table
        end

        def tagging_arel_table
          @tagging_arel_table ||= tagging_model.arel_table
        end

        def tag_translations_arel_table
          return unless tag_model.respond_to?(:translation_class)

          @tag_translations_arel_table ||=
            tag_model.translation_class.with_locale(Globalize.locale).arel_table
        end

        def matches_attribute
          matches_attribute = if tag_translations_arel_table.present?
                                tag_translations_arel_table[:name]
                              else
                                tag_arel_table[:name]
                              end
          return matches_attribute if ActsAsTaggableOn.strict_case_match

          matches_attribute.lower
        end

        def tag_match_type(tag)
          if options[:wild].present?
            matches_attribute.matches("%#{escaped_tag(tag)}%", '!')
          else
            matches_attribute.matches(escaped_tag(tag), '!')
          end
        end

        def tags_match_type
          if options[:wild].present?
            matches_attribute.matches_any(
              tag_list.map { |tag| "%#{escaped_tag(tag)}%" }, '!'
            )
          else
            matches_attribute.matches_any(
              tag_list.map { |tag| escaped_tag(tag).to_s }, '!'
            )
          end
        end

        def escaped_tag(tag)
          tag = tag.downcase unless ActsAsTaggableOn.strict_case_match
          ActsAsTaggableOn::Utils.escape_like(tag)
        end

        def adjust_taggings_alias(taggings_alias)
          if taggings_alias.size > 75
            taggings_alias =
              'taggings_alias_' + Digest::SHA1.hexdigest(taggings_alias)
          end
          taggings_alias
        end
      end
    end
  end
end
