try:
    from odoo import fields, models
except ImportError:
    from openerp import fields, models


class SomeModel(models.Model):
    _name = "some.model"

    some_field2 = fields.Integer(default=1, oldname="some_field")
