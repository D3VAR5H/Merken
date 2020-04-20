from flask import Blueprint, render_template, request, jsonify, redirect, url_for
from .forms import AddPageForm
from run import cur, conn

boardnotes_bp = Blueprint('boardnotes', __name__, template_folder='templates',
                          static_folder='static')
from useraccounts import useraccounts_routes

user = None
user_boards = None
user_pages = None


def get_data():
    global user
    global user_boards
    global user_pages
    if user is None:
        user = useraccounts_routes.get_user()
    useraccounts_routes.load_boards(user['user_id'])
    user_boards = useraccounts_routes.get_boards()
    user_pages = useraccounts_routes.get_pages()


@boardnotes_bp.route('/base/', methods=['POST', 'GET'])
@useraccounts_routes.login_required
def base():
    get_data()
    return render_template('base.html', user=user)


@boardnotes_bp.route('/board/', methods=['POST', 'GET'])
@useraccounts_routes.login_required
def board():
    get_data()
    user_id = user['user_id']
    query = f"SELECT * FROM boards WHERE user_id='{user_id}' and status=true"
    cur.execute(query)
    page = cur.fetchall()
    return render_template('board.html', title='Boards', user=user, user_boards=user_boards,
                           user_pages=user_pages)


@boardnotes_bp.route('/delete_board/<board_id>', methods=['POST', 'GET'])
@useraccounts_routes.login_required
def delete_board(board_id):
    get_data()
    print(board_id)
    query = f"UPDATE boards SET status=false WHERE board_id={board_id}"
    cur.execute(query)
    conn.commit()
    return redirect(url_for('boardnotes.board'))


@boardnotes_bp.route('/add_board/', methods=['POST'])
@useraccounts_routes.login_required
def add_board():
    get_data()
    user_id = user['user_id']
    board_name = request.form['board_name']
    board_desc = request.form['board_desc']
    data = {'board_name': board_name, 'board_desc': board_desc}
    query = f"INSERT INTO boards(board_name, description, status, cover_img, user_id) VALUES ('{board_name}', '{board_desc}', TRUE, NULL, {user_id})"
    cur.execute(query)
    conn.commit()
    return jsonify(data)


@boardnotes_bp.route('/page/<board_id>', methods=['POST', 'GET'])
@useraccounts_routes.login_required
def page(board_id):
    get_data()
    query = f"SELECT * FROM pages WHERE board_id='{board_id}' and status=true"
    cur.execute(query)
    page = cur.fetchall()
    return render_template('page.html', title='Pages', user=user, pages=page, board_id=board_id,
                           user_boards=user_boards, user_pages=user_pages)


@boardnotes_bp.route('/add_page/', methods=['POST'])
@useraccounts_routes.login_required
def add_page():
    get_data()
    page_name = request.form['page_name']
    # page_data = request.form['page_data']
    board_id = request.form['board_id']
    data = {'page_name': page_name}
    query = f"INSERT INTO pages(page_name, board_id) VALUES ('{page_name}', {board_id})"
    cur.execute(query)
    conn.commit()
    return jsonify(data)


@boardnotes_bp.route('/delete_page/<page_id>', methods=['POST', 'GET'])
@useraccounts_routes.login_required
def delete_page(page_id):
    get_data()
    query = f"UPDATE pages SET status=false WHERE page_id={page_id}"
    cur.execute(query)
    conn.commit()
    query = f"SELECT board_id from pages where page_id='{page_id}'"
    cur.execute(query)
    board_id = cur.fetchall()[0][0]
    print(board_id)
    return redirect(url_for('boardnotes.page', board_id=board_id))


@boardnotes_bp.route('/page_editor/<page_id>', methods=['POST', 'GET'])
@useraccounts_routes.login_required
def page_editor(page_id):
    get_data()
    query = f"SELECT * FROM pages WHERE page_id={page_id};"
    cur.execute(query)
    temp = cur.fetchall()
    return render_template('pageEditor.html', user=user, user_boards=user_boards,
                           user_pages=user_pages, page=temp[0])


@boardnotes_bp.route('/add_page_data/<page_id>', methods=['POST'])
@useraccounts_routes.login_required
def add_page_data(page_id):
    get_data()
    form = AddPageForm(request.form)
    page_name = form.page_name.data
    page_data = form.page_data.data
    data = {'page_id': page_id, 'page_name': page_name, 'page_data': page_data}
    query = f"UPDATE pages SET page_data='{page_data}',page_name='{page_name}' WHERE page_id='" \
            f"{page_id}';"
    cur.execute(query)
    conn.commit()
    query = f"SELECT board_id from pages where page_id='{page_id}'"
    cur.execute(query)
    board_id = cur.fetchall()[0][0]
    print(board_id)
    return redirect(url_for('boardnotes.page', board_id=board_id))

# @boardnotes_bp.route('/dashboard/', methods=['POST', 'GET'])
# @useraccounts_routes.login_required
# def dashboard():
#     get_data()
#     return render_template('dashboard.html', title='Welcome', user=user, user_boards=user_boards,
#                            user_pages=user_pages)
