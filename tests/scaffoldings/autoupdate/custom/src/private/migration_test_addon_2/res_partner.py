try:
    from odoo import fields, models
except ImportError:
    from openerp import fields, models


class ResPartner(models.Model):
    _inherit = "res.partner"

    some_field2 = fields.Integer(default=1, oldname="some_field")
