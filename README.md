[![Stories in Ready](https://badge.waffle.io/parti-xyz/catan-web.png?label=ready&title=Ready)](https://waffle.io/parti-xyz/catan-web)
# parti 함께 만드는 온라인 광장 빠띠

## 업그레이드

### 1.3 --> 1.4

서버에 데이터베이스 설정을 수정합니다.
https://support.cloud.engineyard.com/hc/en-us/articles/205407378-Use-Keep-Files-to-Customize-and-Maintain-Configurations

### 1.2 --> 1.3

관리자 암호를 등록해야합니다.
```
export PARTI_ADMIN_PASSWORD="12345678"
```

각 링크/톡/투표에 대해 마지막 수다가 입력된 시간을 마이그레이션 합니다.
```
Post.all.each { |p| p.update_columns(last_commented_at: (p.comments.newest.try(:created_at) || p.created_at)) }
```

현존하는 모든 빠띠의 메이커를 마이그레이션 합니다.
```
Issue.all.select { |i| !i.makers.exists?(user: admin) }.each { |i| i.makers.build(user: admin); i.save }
```

### 0.x --> 1.0

각 빠띠마다 같은 URL의 글이 올란 경우를 찾아 봅니다. 검색이 되면 조치를 취합니다.
```
Article.all.select { |a| Article.joins(:post).where('issue_id': a.issue_id, link_source_id: a.link_source_id).count > 1 }
```

존재하지 않는 사용자가 투표한 데이터를 삭제합니다.

```
Vote.all.select {|v| v.user.nil? }.each {|v| v.destroy }
```

크롤링을 다시 합니다.

```
$ bundle exec rake crawling:reload_all
```

이미지 프로세싱을 다시 합니다

```
$ nohup bin/rake images:reprocess RAILS_ENV=staging > ~/nohup4.out 2>&1&
```

## 배포

engineyard를 사용합니다.

```
$ bin/deploy master
$ bin/deploy dev
$ bin/deploy hotfix
```

## 실환경 구축

mysql의 encoding은 utf8mb4를 사용합니다. mysql은 버전 5.6 이상을 사용합니다.

mysql my.cnf
```
[mysqld]
innodb_file_format=Barracuda
innodb_large_prefix = ON
```

database.yml
```
  encoding:  utf8mb4
  collation: utf8mb4_unicode_ci
```

## 로컬 개발 환경 구축 방법

기본적인 Rail 개발 환경에 rbenv를 이용합니다.

```
$ rbenv install 2.2.3
$ bundle install
$ bundle exec rake db:migrate
```

### 데이터베이스 준비

#### mysql 설정
mysql을 구동해야합니다. mysql의 encoding은 utf8mb4를 사용합니다. mysql은 버전 5.6 이상을 사용합니다.

encoding세팅은 my.cnf에 아래 설정을 넣고 반드시 재구동합니다. 참고로 맥에선 /usr/local/Cellar/mysql/(설치하신 mysql버전 번호)/my.cnf입니다.

```
[mysqld]
innodb_file_format=Barracuda
innodb_large_prefix = ON
```

#### 연결 정보

프로젝트 최상위 폴더에 local_env.yml이라는 파일을 만듭니다. 데이터베이스 연결 정보를 아래와 예시를 보고 적당히 입력합니다.

```
development:
  database:
    username: 사용자이름
    password: 암호
```


#### 스키마

과거 마이그레이션이 정리되지 않아 최초엔 db:migrate가 작동하지 않습니다. db:create와 db:reset으로 생성합니다.

#### 초기 데이터 추가

먼저 .powenv에 원하는 관리자용 암호를 등록합니다.
```
export PARTI_ADMIN_PASSWORD="12345678"
```

[mbleigh/seed-fu](https://github.com/mbleigh/seed-fu) 을 이용하여 설정된 초기 데이터를 로딩합니다.

```
$ source .powenv
$ bundle exec rake db:seed_fu
```

### 메일 확인

http://parti.dev/devel/emails 에서 메일 발송을 확인 할 수 있습니다.

### 인기글 업데이트

http://parti.dev/stat

위 주소에 접근하면 업데이트 됩니다.

### 포스트마커 연동

.powenv에 API키를 등록 합니다.

```
export POSTMARKER_API_KEY="키값"
```

### 사용자 임시 삭제

```
http://parti.dev/kill_me
```

## 빠띠 테스트서버 관리

주의 : 아래 관리 방법은 parti.xyz에서 테스트서버를 관리하는 팁입니다.

### 실서버 이미지를 테스트서버로 이관하기

omurice에서 실행합니다

```
$ rm -rf /home/deploy/test/files/uploads

$ s3cmd sync s3://catan-file/uploads /home/deploy/test/files -c ~/.s3cfg.production

$ s3cmd sync /home/deploy/test/files/uploads/ s3://catan-file-dev/uploads/
```

## 데이터 관리

### 아래를 rails console에서 수행하면 지워진 글의 수다를 삭제합니다

Comment.all.each { |c| c.destroy if c.post.blank? }

### 크롤링

실패한 크롤링

```
$ bundle exec rake crawling:fails
```

특정 크롤링 다시 수행
```
$ bundle exec rake crawling:reload[아이디값]
```

모든 크롤링 다시 수행

```
$ bundle exec rake crawling:reload_all
```

