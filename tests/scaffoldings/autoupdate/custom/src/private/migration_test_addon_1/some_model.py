try:
    from odoo import fields, models
except ImportError:
    from openerp import fields, models


class SomeModel(models.Model):
    _name = "some.model"

    some_field = fields.Integer(default=0)
