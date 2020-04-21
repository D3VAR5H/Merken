import binascii
import hashlib
import string
from functools import wraps
import random

from flask import render_template, Blueprint, request, redirect, url_for
from .forms import SignUpForm, LoginForm, RecoverPasswordForm, EditProfileForm
from run import conn, cur

useraccounts_bp = Blueprint('useraccounts', __name__, template_folder='templates', static_folder='static')
user = None
user_boards = []
user_pages = []


def get_user():
    global user
    return user


def get_boards():
    global user_boards
    return user_boards


def get_pages():
    global user_pages
    return user_pages


def load_boards(user_id):
    global user_boards
    user_boards = []
    global user_pages
    user_pages = []
    query = f"SELECT board_id,board_name,description FROM boards WHERE user_id={user_id} AND status=true"
    cur.execute(query)
    temp = cur.fetchall()
    for i in temp:
        user_boards.append(i)
    for user_board in user_boards:
        load_pages(user_board[0])


def load_pages(board_id):
    query = f"SELECT page_id, page_name, page_data, board_id FROM pages WHERE board_id={board_id} AND status=true"
    cur.execute(query)
    temp = cur.fetchall()
    for i in temp:
        user_pages.append(i)


def load_user(user_id):
    query = f"SELECT * FROM users WHERE user_id={user_id}"
    cur.execute(query)
    temp1 = cur.fetchall()
    load_boards(temp1[0][0])
    global user
    user = {'user_id': temp1[0][0], 'username': temp1[0][1], 'email_id': temp1[0][3], 'joining_date': temp1[0][4],
            'birth_date': temp1[0][5], 'name': temp1[0][6], 'bio': temp1[0][7], 'fb_handle': temp1[0][8],
            'ig_handle': temp1[0][9], 'twitter_handle': temp1[0][10], 'linkedin_handle': temp1[0][11],
            'github_handle': temp1[0][12], 'profile_pic': temp1[0][13]}


def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if user is None:
            return redirect(url_for('useraccounts.login', c=request.url))
        return f(*args, **kwargs)

    return decorated_function


def hash_password(password):
    pwdhash = hashlib.pbkdf2_hmac('sha512', password.encode('utf-8'), ''.encode('utf-8'), 100000)
    pwdhash = binascii.hexlify(pwdhash)
    return str(pwdhash.decode('ascii'))


def valid_email(email):
    import requests
    email_address = email
    response = requests.get("https://isitarealemail.com/api/email/validate", params={'email': email_address})
    print(response.json()['status'])
    if response.json()['status'] == 'valid':
        return True
    return False


@useraccounts_bp.route('/signup/', methods=['POST', 'GET'])
def signup():
    print(request.form.get('dob'))
    form = SignUpForm(request.form)
    if request.method == 'POST' and form.check_username(form.username.data) and form.check_email(
            form.email.data) and valid_email(form.email.data) and form.check_passwords(form.pwd.data,
                                                                                       form.pwd_confirm.data) and form.check_name(
            form.name.data):
        try:
            query = f"INSERT INTO Users(username, pwd, email_id, user_name, birth_date) VALUES ('{form.username.data}', '{hash_password(form.pwd.data)}', '{form.email.data}', '{form.name.data}', '{form.dob.data}')"
            cur.execute(query)
            conn.commit()
            return redirect(url_for('useraccounts.login'))
        except:
            print('User Already exists')
    return render_template('signup.html', title='Sign Up', form=form)


@useraccounts_bp.route('/login/', methods=['POST', 'GET'])
def login():
    form = LoginForm(request.form)
    if request.method == 'POST':
        try:
            query = f"SELECT user_id FROM users WHERE (username='{form.username_email.data}' AND pwd='{hash_password(form.pwd.data)}') OR (email_id='{form.username_email.data}' AND pwd='{hash_password(form.pwd.data)}');"
            cur.execute(query)
            temp = cur.fetchall()
            print(temp)
            user_id = temp[0][0]
            load_user(user_id)
            if len(temp) != 0:
                if request.values.get("c") is not None:
                    return redirect(f'{request.values.get("c")}')
                return redirect(url_for('boardnotes.board'))
        except:
            print('invalid')
    return render_template('login.html', title='Login', form=form)


@useraccounts_bp.route('/recover_password/', methods=['POST', 'GET'])
def recover_password():
    form = RecoverPasswordForm(request.form)
    if request.method == 'POST' and form.check_email(form.email.data):
        lettersAndDigits = string.ascii_letters + string.digits
        pwd = ''.join(random.choice(lettersAndDigits) for i in range(16))
        print(pwd)
        try:
            query = f"UPDATE Users SET pwd='{hash_password(pwd)}' WHERE email_id = '{form.email.data}'"
            cur.execute(query)
            conn.commit()
        except:
            print('No account is linked to this email')
        return redirect(url_for('useraccounts.login'))
    return render_template('recover_password.html', title='Recover Password', form=form)


@useraccounts_bp.route('/profile/', methods=['POST', 'GET'])
@login_required
def profile():
    load_user(user['user_id'])
    form = EditProfileForm(request.form)
    if request.method == 'POST':
        # profile_photo = request.files["image"]
        query = [user['user_id'], '', form.profile_name.data, form.profile_bio.data,
                 form.fb_handle.data, form.twitter_handle.data, form.ig_handle.data,
                 form.linkedIn_handle.data, form.github_handle.data, hash_password(form.pwd.data),
                 hash_password(form.pwd_repeat.data)]
        print(query)
        final_pwd = ''
        if form.pwd.data == form.pwd_repeat.data and (form.pwd.data is not '' or form.pwd.data is not None):
            final_pwd = form.pwd.data

        cur.callproc('user_profile_updates', [user['user_id'], '', form.profile_name.data, form.profile_bio.data,
                                              form.fb_handle.data, form.twitter_handle.data, form.ig_handle.data,
                                              form.linkedIn_handle.data, form.github_handle.data,
                                              hash_password(final_pwd), ])
        temp = cur.fetchall()
        conn.commit()
        return redirect(url_for('useraccounts.profile'))

    cur.callproc('get_active_months', [user['user_id'], ])
    temp = cur.fetchall()
    month = [temp]
    month = list(dict.fromkeys(month[0]))

    cur.callproc('get_logs', [user['user_id'], ])
    temp = cur.fetchall()
    data = [temp]

    logs = {'month': month, 'data': data}

    return render_template('profile.html', title='Profile', user=user, user_boards=user_boards, user_pages=user_pages,
                           logs=logs)


@useraccounts_bp.route('/profile/timeline', methods=['POST', 'GET'])
@login_required
def timeline():
    cur.callproc('get_active_months', [user['user_id'], ])
    temp = cur.fetchall()
    month = [temp]
    month = list(dict.fromkeys(month[0]))

    cur.callproc('get_logs', [user['user_id'], ])
    temp = cur.fetchall()
    data = [temp]

    logs = {'month': month, 'data': data}
    print(logs)
    return render_template('timeline.html', title='Timeline', user=user, user_boards=user_boards, user_pages=user_pages,
                           logs=logs)


@useraccounts_bp.route('/logout/', methods=['POST', 'GET'])
def logout():
    global user
    user = None
    return redirect(url_for('useraccounts.login'))
