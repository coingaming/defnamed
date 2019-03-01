[
  inputs: [".credo.exs", ".formatter.exs", "mix.exs", "{config,lib,priv,rel,test}/**/*.{ex,exs}"],
  line_length: 140,
  locals_without_parens: [
    # Ecto

    ## schema
    field: :*,
    belongs_to: :*,
    has_one: :*,
    has_many: :*,
    many_to_many: :*,
    embeds_one: :*,
    embeds_many: :*,

    ## migration
    create: :*,
    create_if_not_exists: :*,
    alter: :*,
    drop: :*,
    drop_if_exists: :*,
    rename: :*,
    add: :*,
    remove: :*,
    modify: :*,
    execute: :*
  ]
]
