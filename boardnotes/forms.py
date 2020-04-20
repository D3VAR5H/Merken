from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, TextAreaField
from wtforms.validators import DataRequired


class AddPageForm(FlaskForm):
    page_name = StringField("Name", validators=[DataRequired()])
    page_data = TextAreaField("Enter Description")
    submit = SubmitField("Add")
