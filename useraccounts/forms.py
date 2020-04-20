from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, BooleanField, DateField, FileField, TextAreaField
from wtforms.validators import DataRequired, Email, EqualTo, Length, URL

from run import cur


class SignUpForm(FlaskForm):
    name = StringField("Name", validators=[DataRequired()])
    username = StringField("Enter your Username", validators=[DataRequired(), Length(min=2, max=20)])
    email = StringField("What's your Email?", validators=[DataRequired(), Email()])
    dob = DateField("dd/mm/yyyy", format='%Y-%m-%d')
    pwd = PasswordField("Pick a Password", validators=[DataRequired(), Length(min=8, max=16)])
    pwd_confirm = PasswordField("Re-enter your Password", validators=[DataRequired(), EqualTo('pwd')])
    agree_terms = BooleanField("I agree with terms of use")
    submit = SubmitField("Sign Up")

    @staticmethod
    def check_name(name):
        if name is None:
            return False
        return True

    @staticmethod
    def check_username(username):
        query = f"SELECT COUNT(*) FROM Users WHERE username='{username}'"
        cur.execute(query)
        if cur.fetchall()[0][0] != 0:
            return False
        return True

    @staticmethod
    def check_email(emailId):
        query = f"SELECT COUNT(*) FROM Users WHERE email_id='{emailId}'"
        cur.execute(query)
        if cur.fetchall()[0][0] != 0:
            return False
        return True

    @staticmethod
    def check_passwords(password1, password2):
        if password1 != password2:
            return False
        return True


class LoginForm(FlaskForm):
    username_email = StringField("Username or Email", validators=[DataRequired()])
    pwd = PasswordField("Password", validators=[DataRequired()])
    remember = BooleanField("Remember me")
    submit = SubmitField("Login")


class RecoverPasswordForm(FlaskForm):
    email = StringField("Email", validators=[DataRequired(), Email()])
    submit = SubmitField("Submit")

    @staticmethod
    def check_email(emailId):
        query = f"SELECT COUNT(*) FROM Users WHERE email_id='{emailId}'"
        cur.execute(query)
        if cur.fetchall()[0][0] != 0:
            return True
        return False


class EditProfileForm(FlaskForm):
    # profile_pic = FileField("Choose File")
    profile_name = StringField("Enter your Name")
    profile_bio = TextAreaField()
    fb_handle = StringField("Enter your Facebook link", validators=[URL])
    twitter_handle = StringField("Enter your Twitter link", validators=[URL])
    ig_handle = StringField("Enter your Instagram link", validators=[URL])
    linkedIn_handle = StringField("Enter your LinkedIn link", validators=[URL])
    github_handle = StringField("Enter your Github link", validators=[URL])
    pwd = PasswordField('Enter your new password')
    pwd_repeat = PasswordField('Re-Enter your new password', validators=[EqualTo(pwd)])
    submit = SubmitField("Submit")
