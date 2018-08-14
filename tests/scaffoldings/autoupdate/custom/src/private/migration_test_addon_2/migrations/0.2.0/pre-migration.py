def migrate(cr, version):
    cr.execute("""UPDATE res_partner SET some_field = some_field + 1""")
