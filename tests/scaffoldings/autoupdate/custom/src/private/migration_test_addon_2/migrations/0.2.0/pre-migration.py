def migrate(cr, version):
    cr.execute("""UPDATE some_model SET some_field = some_field + 1""")
